pipeline 
{
    agent any
    stages 
    {
        stage('Build') 
        {
            steps 
            {
                podTemplate(yamlFile: pod-template.yaml) 
                {
                    node(POD_LABEL)
                    {
                        container('shell')
                        {
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
