<%namespace file="ie.mako" name="ie"/>
<%
import os
import shutil
import tempfile
import time
import subprocess

# Sets ID and sets up a lot of other variables
ie_request.load_deploy_config()
ie_request.attr.docker_port = 80
# Create tempdir in galaxy
temp_dir = os.path.abspath( tempfile.mkdtemp() )
PASSWORD = ie_request.notebook_pw
USERNAME = "galaxy"

## General IE specific
# Access URLs for the notebook from within galaxy.
# TODO: Make this work without pointing directly to IE. Currently does not work
# through proxy.
notebook_pubkey_url = ie_request.url_template('${PROXY_URL}/rstudio/${PORT}/auth-public-key')
notebook_access_url = ie_request.url_template('${PROXY_URL}/rstudio/${PORT}/')
notebook_login_url =  ie_request.url_template('${PROXY_URL}/rstudio/${PORT}/auth-do-sign-in')

# Did the user give us an RData file?
if hda.datatype.__class__.__name__ == "RData":
    shutil.copy( hda.file_name, os.path.join(temp_dir, '.RData') )

import re
docker_cmd = ie_request.docker_cmd(temp_dir, env_override={
    'notebook_username': USERNAME,
    'notebook_password': PASSWORD,
    'cors_origin': ie_request.attr.proxy_url})
# Hack out the -u galaxy_id statement because the RStudio IE isn't ready to run
# as root
docker_cmd = re.sub('-u (\d+) ', '', docker_cmd)
# Add in ENV parameters
docker_cmd = docker_cmd.replace('run', 'run %s' % ENV)
subprocess.call(docker_cmd, shell=True)
ie_request.log.info("Starting RStudio docker container with command [%s]" % docker_cmd)
%>
<html>
<head>
${ ie.load_default_js() }
</head>
<body style="margin:0px">
<script type="text/javascript">
${ ie.default_javascript_variables() }
var notebook_login_url = '${ notebook_login_url }';
var notebook_access_url = '${ notebook_access_url }';
var notebook_pubkey_url = '${ notebook_pubkey_url }';
var notebook_username = '${ USERNAME }';
require.config({
    baseUrl: app_root,
    paths: {
        "interactive_environments": "${h.url_for('/static/scripts/galaxy.interactive_environments')}",
        "plugin" : app_root + "js/",
        "crypto" : app_root + "js/crypto/",
    },
});
requirejs([
    'interactive_environments',
    'crypto/prng4',
    'crypto/rng',
    'crypto/rsa',
    'crypto/jsbn',
    'crypto/base64',
    'plugin/rstudio'
], function(){
    load_notebook(notebook_login_url, notebook_access_url, notebook_pubkey_url, "${ USERNAME }");
});
</script>
<div id="main">
</div>
</body>
</html>
