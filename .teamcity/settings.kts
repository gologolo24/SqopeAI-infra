import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.PullRequests
import jetbrains.buildServer.configs.kotlin.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.buildFeatures.pullRequests
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

/*
 * TeamCity pipeline for sqope-ai-infra (Kotlin DSL, versioned in this repo, so a pipeline change
 * goes through code review like any other change).
 *
 *   Pull request :  1. Validate ──► 2. Plan dev | Plan staging | Plan prod      (read-only role)
 *   Merge to main:  1. Validate ──► 3. Apply dev ──► 3. Apply staging ──► 3. Apply prod
 *                                     (automatic)      (automatic)          (MANUAL)
 *
 * Credentials: agents run in the tooling AWS account with an instance role and assume
 * terraform-planner / terraform-deployer in each environment account (see live/root.hcl).
 * There are no AWS keys anywhere in TeamCity.
 */

version = "2025.03"

val environments = listOf("dev", "staging", "prod")

// Every step runs in the same pinned toolbox image: terraform 1.16.6, terragrunt 1.2.3, trivy.
val toolbox = "%toolbox.image%"

val infraRepo = GitVcsRoot({
    id("InfraRepo")
    name = "sqope-ai-infra"
    url = "https://github.com/gologolo24/sqope-ai-infra.git"
    branch = "refs/heads/main"
    branchSpec = "+:refs/heads/*"
    authMethod = password {
        userName = "x-access-token"
        // Stored encrypted in TeamCity; only this reference lives in git.
        password = "credentialsJSON:REPLACE-WITH-TEAMCITY-SECURE-TOKEN-ID"
    }
})

// PR integration: build GitHub pull requests (from org members only, since the repo is public)
// and report each build's result back to the PR as a status check.
fun BuildType.reportToGitHub() {
    features {
        pullRequests {
            vcsRootExtId = "${infraRepo.id}"
            provider = github {
                authType = vcsRoot()
                filterTargetBranch = "+:<default>"
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
        commitStatusPublisher {
            vcsRootExtId = "${infraRepo.id}"
            publisher = github {
                githubUrl = "https://api.github.com"
                authType = vcsRoot()
            }
        }
    }
}

// ---- 1. Validate: fast, no AWS credentials, runs on every branch and PR ---------------------
val validate = BuildType({
    id("Validate")
    name = "1. Validate"
    description = "fmt + validate + security scan. No AWS access needed."
    vcs { root(infraRepo) }

    steps {
        script {
            name = "Format check"
            dockerImage = toolbox
            scriptContent = """
                set -eu
                terraform fmt -check -recursive modules
                terragrunt hcl fmt --check --working-dir live
            """.trimIndent()
        }
        script {
            name = "Validate modules and Terragrunt config"
            dockerImage = toolbox
            scriptContent = """
                set -eu
                terraform -chdir=modules/vpc init -backend=false -input=false && terraform -chdir=modules/vpc validate
                terraform -chdir=modules/eks init -backend=false -input=false && terraform -chdir=modules/eks validate
                terraform -chdir=modules/rds init -backend=false -input=false && terraform -chdir=modules/rds validate
                terragrunt hcl validate --working-dir live
            """.trimIndent()
        }
        script {
            name = "Security scan (trivy config)"
            dockerImage = toolbox
            scriptContent = """
                trivy config --severity HIGH,CRITICAL --exit-code 1 \
                  --ignorefile .trivyignore --skip-dirs '**/.terraform/modules/*/examples' modules/
            """.trimIndent()
        }
    }

    triggers { vcs { branchFilter = "+:*" } }
    reportToGitHub()
})

// ---- 2. Plan <env>: on pull requests, read-only role, plan saved as an artifact for review --
fun planBuild(env: String) = BuildType({
    id("Plan_$env")
    name = "2. Plan $env"
    description = "terragrunt plan for every component in $env (read-only terraform-planner role)"
    vcs { root(infraRepo) }
    params { param("env.TF_ROLE_NAME", "terraform-planner") }

    steps {
        script {
            name = "terragrunt run --all plan ($env)"
            dockerImage = toolbox
            scriptContent = """
                set -euo pipefail
                terragrunt run --all --working-dir live/$env --non-interactive -- plan -input=false -no-color | tee plan-$env.txt
            """.trimIndent()
        }
    }
    artifactRules = "plan-$env.txt"

    dependencies {
        snapshot(validate) { onDependencyFailure = FailureAction.FAIL_TO_START }
    }
    triggers { vcs { branchFilter = "+:pull/*" } }
    reportToGitHub()
})

// ---- 3. Apply <env>: main branch only, deployer role, one apply per environment at a time ---
fun applyBuild(env: String, after: BuildType) = BuildType({
    id("Apply_$env")
    name = "3. Apply $env"
    vcs {
        root(infraRepo)
        branchFilter = "+:<default>" // never apply from a PR branch
    }
    params { param("env.TF_ROLE_NAME", "terraform-deployer") }

    steps {
        script {
            name = "terragrunt run --all apply ($env)"
            dockerImage = toolbox
            // run --all applies in dependency order (vpc -> eks -> rds) and auto-approves
            scriptContent = "terragrunt run --all --working-dir live/$env --non-interactive -- apply -input=false"
        }
    }

    // Snapshot dependency: this env applies the SAME commit that already succeeded in the previous one.
    dependencies {
        snapshot(after) {
            onDependencyFailure = FailureAction.FAIL_TO_START
            reuseBuilds = ReuseBuilds.SUCCESSFUL
        }
    }
    maxRunningBuilds = 1
})

val applyDev = applyBuild("dev", after = validate).apply {
    triggers { vcs { branchFilter = "+:<default>" } } // every merge to main
}

val applyStaging = applyBuild("staging", after = applyDev).apply {
    triggers {
        finishBuildTrigger { // automatically after dev succeeds
            buildType = "${applyDev.id}"
            successfulOnly = true
            branchFilter = "+:<default>"
        }
    }
}

// No trigger on purpose: a human reviews the prod plan, then clicks Run (or "Promote" on the
// staging build) to apply exactly what was applied to staging.
val applyProd = applyBuild("prod", after = applyStaging)

project {
    description = "Sqope AI infrastructure: Terraform modules + Terragrunt (dev / staging / prod)"
    vcsRoot(infraRepo)

    params {
        param("toolbox.image", "ghcr.io/sqope-ai/infra-toolbox:tf-1.16.6-tg-1.2.3")
    }

    buildType(validate)
    environments.forEach { buildType(planBuild(it)) }
    buildType(applyDev)
    buildType(applyStaging)
    buildType(applyProd)
}
