pipeline 
{
    agent any
    stages 
    {
        stage('Build') 
        {
            steps
            {
                /*
 * Runs a build on a Windows pod.
 * Tested in EKS: https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html
 */
podTemplate(yamlFile: pod-template.yaml) {
    node(POD_LABEL) {
        container('shell') {
            powershell 'Get-ChildItem Env: | Sort Name'
        }
    }
}

            }
        }
        stage('Test')
        {
            steps
            {
                println 'Testing'
            }
        }
        stage('Deploy') 
        {
            steps 
            {
                println 'Deploying'
            }
        }
    }
}
