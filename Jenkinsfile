properties([
        pipelineTriggers([
                [$class: 'GitHubPushTrigger'], pollSCM('*/1 * * * *')
        ])
])

node {
	ws("workspace/${env.JOB_NAME}/${env.BUILD_NUMBER}".replace('%2F', '_')) { 
		def ARTIFACT_VERSION;

		def GIT_REPOSITORY;
		def GIT_BRANCH_NAME;
		def GIT_COMMIT_ID;
		
		def DOCKER_IMAGE_NAME;
		def DOCKER_IMAGE;

        try {
            stage("Checkout source") {
                def scmVars = checkout scm
                GIT_REPOSITORY = scmVars.GIT_URL
                GIT_BRANCH_NAME = scmVars.GIT_BRANCH
                GIT_COMMIT_ID = scmVars.GIT_COMMIT
            }

            stage("Create version number") {
                ARTIFACT_VERSION = (GIT_BRANCH_NAME + "-" + GIT_COMMIT_ID).replaceAll("[^\\w-]", "_")
                sh "git branch ${ARTIFACT_VERSION}"
            }

            stage("Build opsgenie-heartbeat-proxy image") {
                DOCKER_IMAGE_NAME = "opsgenie-heartbeat-proxy:" + ARTIFACT_VERSION;

                DOCKER_IMAGE = docker.build(
                    DOCKER_IMAGE_NAME, 
                    [
                        [
                            "GIT_REPOSITORY=${GIT_REPOSITORY}",
                            "GIT_BRANCH_NAME=${GIT_BRANCH_NAME}",
                            "GIT_COMMIT_ID=${GIT_COMMIT_ID}",
                            "ARTIFACT_VERSION=${ARTIFACT_VERSION}"
                        ].collect { "--build-arg ${it.toString()}" }.join(" "),
                        "-f Dockerfile",
                        "."
                    ].join(" ")
                )
            }

            stage("Publish version") {
                // git
                sshagent(credentials: ["jenkinsSSH"]) {
                    sh """
                        git config user.email 'ci-server@weekendesk.com'
                        git config user.name 'CI Server'
                        git tag ${ARTIFACT_VERSION}
                        git branch -D ${ARTIFACT_VERSION}
                        git push origin --tags
                    """
                }

                // docker
                docker.withRegistry(env.PRIVATE_DOCKER_REGISTRY_URL, 'DOCKER_REGISTRY_USER') {
                    DOCKER_IMAGE.push(ARTIFACT_VERSION)
                    dockerFingerprintFrom dockerfile: 'Dockerfile', image: DOCKER_IMAGE_NAME
                }

                // jenkins
                currentBuild.displayName = ARTIFACT_VERSION
            }

        } finally {
            stage("Clean directory") {
                deleteDir();
            }
        }
	}
}
