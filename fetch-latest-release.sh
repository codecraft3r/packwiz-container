#!/bin/sh

# Function to construct GitHub raw URL from environment variables
construct_github_packwiz_url() {
    local username="$1"
    local repo="$2"
    local version="$3"
    local file_path="pack.toml"
    
    if [ -z "$username" ] || [ -z "$repo" ]; then
        echo ""
        return 1
    fi
    
    # If version is not specified, fetch latest release
    if [ -z "$version" ]; then
        echo "No version specified, fetching latest release for $username/$repo..." >&2
        local api_response
        api_response=$(curl -s -A "packwiz-container/1.0" -w "\n%{http_code}" "https://api.github.com/repos/$username/$repo/releases/latest")
        local http_code=$(echo "$api_response" | tail -n1)
        local json_body=$(echo "$api_response" | head -n -1)
        
        if [ "$http_code" = "403" ]; then
            echo "Warning: GitHub API rate limit exceeded (HTTP 403). Using 'main' branch." >&2
            version="main"
        elif [ "$http_code" != "200" ]; then
            echo "Warning: GitHub API returned HTTP $http_code. Using 'main' branch." >&2
            version="main"
        else
            local latest_tag
            latest_tag=$(echo "$json_body" | jq -r '.tag_name // empty')
            
            if [ -z "$latest_tag" ] || [ "$latest_tag" = "null" ]; then
                echo "Warning: No releases found for $username/$repo. Using 'main' branch." >&2
                version="main"
            else
                version="$latest_tag"
                echo "Latest release found: $version" >&2
            fi
        fi
    else
        echo "Using specified version: $version" >&2
    fi
    
    # Construct the raw GitHub URL
    local github_url="https://raw.githubusercontent.com/$username/$repo/$version/$file_path"
    echo "Constructed GitHub URL: $github_url" >&2
    
    # Verify the file exists (try multiple methods)
    local http_code
    http_code=$(curl -s -A "packwiz-container/1.0" -o /dev/null -w "%{http_code}" "$github_url")
    
    if [ "$http_code" = "200" ]; then
        echo "$github_url"
    else
        echo "Warning: HTTP $http_code for $github_url, but proceeding anyway..." >&2
        echo "$github_url"
    fi
}

# Function to resolve packwiz URL from either direct URL or GitHub components
resolve_packwiz_url() {
    # Debug: Show current environment variables
    echo "Debug: Environment variables:" >&2
    echo "  PACKWIZ_URL='$PACKWIZ_URL'" >&2
    echo "  GH_USERNAME='$GH_USERNAME'" >&2
    echo "  GH_REPO='$GH_REPO'" >&2
    echo "  PACK_VERSION='$PACK_VERSION'" >&2
    
    # Priority 1: Use PACKWIZ_URL if set
    if [ -n "$PACKWIZ_URL" ]; then
        echo "Using direct PACKWIZ_URL: $PACKWIZ_URL" >&2
        echo "$PACKWIZ_URL"
        return 0
    fi
    
    # Priority 2: Construct from GitHub environment variables
    if [ -n "$GH_USERNAME" ] && [ -n "$GH_REPO" ]; then
        echo "Constructing URL from GitHub environment variables:" >&2
        echo "  Username: $GH_USERNAME" >&2
        echo "  Repository: $GH_REPO" >&2
        echo "  Version: $([ -n "$PACK_VERSION" ] && echo "$PACK_VERSION" || echo "latest")" >&2
        
        local constructed_url
        constructed_url=$(construct_github_packwiz_url "$GH_USERNAME" "$GH_REPO" "$PACK_VERSION")
        
        if [ $? -eq 0 ] && [ -n "$constructed_url" ]; then
            echo "$constructed_url"
            return 0
        else
            echo "Error: Failed to construct valid GitHub URL" >&2
            return 1
        fi
    fi
    
    echo "Error: Neither PACKWIZ_URL nor GitHub variables (GH_USERNAME, GH_REPO) are set" >&2
    echo "Available environment variables:" >&2
    env | grep -E "(PACKWIZ|GH_|PACK_)" | sort >&2
    return 1
}

# If script is called directly (not sourced), resolve the URL
if [ "$(basename "$0")" = "fetch-latest-release.sh" ]; then
    resolve_packwiz_url
fi