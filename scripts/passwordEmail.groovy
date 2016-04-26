#!/usr/bin/env groovy

def userList = args[0]  // file that contains "email userid password" tuples. generated from passwordReset.groovy"
def apiKey = args[1]
def contentFile = args[2]

content = new File(contentFile).text

new File(userList).eachLine { l ->
    def tokens = l.split("\t")
    def email = tokens[0];
    def userid = tokens[1];
    def password = tokens[2];

    int exitCode = new ProcessBuilder([
            "curl",
            "-s",       // silent
            "-S",       // show error
            "--fail",   // I want to know if it fails
            "--user", apiKey,
            "https://api.mailgun.net/v3/jenkins.io/messages",

            "-F", "from=Jenkins <noreply@jenkins.io>",
            "-F", "to=" +email,
            "-F", "subject=Important: Password reset of your Jenkins community account",
            "-F", "text=" +content.replace("{USERID}",userid).replace("{PASSWORD}",password)
    ]).inheritIO().start().waitFor()

    if (exitCode==0)
        System.out.println("SUCCESS "+userid);
    else
        System.out.println("FAILURE "+userid);
}
