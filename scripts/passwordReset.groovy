#!/usr/bin/env groovy
/*
    stream processor from stdin to stdout.
    user records in ldif format is expected as input,
    and it resets the password that it discovers to some random value.
    
    username & email address is recorded on the side into a separate file
    specified as args[0] in tab-separated format.
*/

@Grab("commons-codec:commons-codec:1.10")
import org.apache.commons.codec.binary.Base64;
import java.security.*;

MD = MessageDigest.getInstance("sha1")
SR = new SecureRandom()

main()
System.exit(0)

//================================================================


// main loop
def main() {
  mail = null;
  username = null;
  password = null;

  // Our LDAP server has some additional special user accounts that shouldn't be reset
  normalUser = false;

  side = new PrintWriter(new FileWriter(args[0]));

  System.in.eachLine { l ->
    // replace password
    if (l.startsWith("userPassword:: ") && normalUser) {
      l = "userPassword:: "+base64(ssha(password=randomString(32),randomString(4)).bytes)
    }
    
    System.out.println(l)
    
    
    if (l=="") {
      if (mail!=null && username!=null) {
        side.println(mail+"\t"+username+"\t"+password);
      }
      mail = null;
      username = null;
      normalUser = false;
      return;
    }
    if (l.startsWith("dn: ") && l.contains(",ou=people,dc=jenkins-ci,dc=org")) {
      normalUser = true;
      return;
    }
    if (l.startsWith("cn: ")) {
      username = value(l);
      return;
    }
    if (l.startsWith("mail: ")) {
      mail = value(l);
      return;
    }
  }
}


// extract value from LDAP field
def value(String s) {
  return s.substring(s.indexOf(": ")+2)
}

// compute SSHA encoded password value with given salt
def ssha(pw,salt) {
  return "{SSHA}"+base64(join( sha1((pw+salt).bytes), salt.bytes))
}

def base64(data) {
  return new String(Base64.encodeBase64(data))
}

def sha1(data) {
  return MD.digest(data)
}

// join two byte array
def join(a,b) {
  byte[] c = new byte[a.length + b.length];
  System.arraycopy(a, 0, c, 0, a.length);
  System.arraycopy(b, 0, c, a.length, b.length);
  return c
}

// compute random string of length n
def randomString(n) {
  def s = new StringBuilder();
  (1..n).each {
    s += (char)(((char)'a')+SR.nextInt(26))
  }
  return s;
}
