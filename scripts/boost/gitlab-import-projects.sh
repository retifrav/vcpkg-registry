#!/bin/bash

# https://gitlab.YOUR.HOST/api/v4
GITLAB_API_BASE_URL='[unknown]'
# probably better to pass it as an environment variable (so it leaves no trace in shell)
GITLAB_API_ACCESS_TOKEN='[unknown]'
# group ID under which the projects/repositories will be imported
GITLAB_GROUP_ID='[unknown]'
# plain-text file with Boost components names (one per line)
BOOST_COMPONENTS='./components.txt'

helpMessage="
Mass-importing Boost repositories from GitHub into a GitLab instance. Disables a lot of useless
GitLab project features along the way.

Example:

  $(basename $0) \\
      [-b ./components.txt] \\
      -u 'https://gitlab.YOUR.HOST/api/v4' \\
      -t 'glpat-YOUR-GITLAB-ACCESS-TOKEN' \\
      -g 1354

For some repositories it might fail with \"Unable to access repository\", like:

\`\`\`
[mqtt5]
{\"message\":\"Unable to access repository with the URL and credentials provided\"}

[units]
{\"message\":\"Unable to access repository with the URL and credentials provided\"}
\`\`\`

which is fuck knows why, since the API access token is the absolute fucking same for every request,
but actually this error is not about your token/credentials for GitLab but about GitHub repositories,
because (fuck knows why) GitLab cannot validate some of them (these two in particular).

So for these problematic repositories you would have to do the importing manually via the GitLab's web UI,
but it will fucking fail with the same error there too, so you'll have to fallback to creating those projects
from scratch. Well, actually, it is still possible to do the import via web UI by overriding the frontend
user input checks with a successful response: https://gitlab.com/gitlab-org/gitlab/-/issues/366769#note_3002955430"

while getopts ":b:u:t:g:h" opt; do
    case $opt in
        b) BOOST_COMPONENTS="$OPTARG"
        ;;
        u) GITLAB_API_BASE_URL="$OPTARG"
        ;;
        t) GITLAB_API_ACCESS_TOKEN="$OPTARG"
        ;;
        g) GITLAB_GROUP_ID="$OPTARG"
        ;;
        h)
            echo "$helpMessage"
            exit 0
        ;;
        \?)
            echo "Unknown option -$OPTARG" >&2
            exit 1
        ;;
    esac
done

if [[ "$GITLAB_API_BASE_URL" == '[unknown]' || "$GITLAB_API_ACCESS_TOKEN" == '[unknown]' || "$GITLAB_GROUP_ID" == '[unknown]' ]]; then
    echo "You need to provide GitLab API base URL (-u), access token (-t) and group ID (-g)" >&2
    exit 1
fi

if [[ ! -f $BOOST_COMPONENTS ]]; then
    echo "[ERROR] Couldn't find the file with Boost components names"
    exit 1
fi

jqPath=$(which jq)
if [ $? -eq 0 ]; then
    echo "Found jq: $jqPath"
else
    echo "[ERROR] Did not find jq, you need to make it available in PATH" >&2
    exit 2
fi

curlPath=$(which curl)
if [ $? -eq 0 ]; then
    echo "Found cURL: $curlPath"
else
    echo "[ERROR] Did not find cURL, you need to make it available in PATH" >&2
    exit 2
fi

while IFS= read -r boostComponent; do
    printf "\n[$boostComponent]\n"
    jq -nc \
        --arg description "https://github.com/boostorg/$boostComponent" \
        --arg import_url "https://github.com/boostorg/$boostComponent.git" \
        --arg path "$boostComponent" \
        --argjson namespace_id $GITLAB_GROUP_ID \
    '{
          "analytics_access_level": "disabled",
          "auto_devops_enabled": false,
          "builds_access_level": "disabled",
          "description": $description,
          "environments_access_level": "disabled",
          "feature_flags_access_level": "disabled",
          "forking_access_level": "disabled",
          "import_url": $import_url,
          "infrastructure_access_level": "disabled",
          "issues_access_level": "disabled",
          "lfs_enabled": true,
          "merge_requests_access_level": "disabled",
          "model_experiments_access_level": "disabled",
          "model_registry_access_level": "disabled",
          "monitor_access_level": "disabled",
          "namespace_id": $namespace_id,
          "package_registry_access_level": "disabled",
          "packages_enabled": false,
          "pages_access_level": "disabled",
          "path": $path,
          "releases_access_level": "disabled",
          "requirements_access_level": "disabled",
          "security_and_compliance_access_level": "disabled",
          "snippets_access_level": "disabled",
          "visibility": "internal",
          "wiki_access_level": "disabled"
    }' \
    | curl -s -X POST "$GITLAB_API_BASE_URL/projects" \
    -H "Authorization: Bearer $GITLAB_API_ACCESS_TOKEN" \
    -H 'Content-Type: application/json; charset=utf-8' \
    -d @- \
    -w '\n'
done < $BOOST_COMPONENTS
