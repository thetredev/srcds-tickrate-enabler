#!/bin/bash


first_tag=$(git tag --sort=-version:refname | head -n 2 | tail -1)
second_tag=$(git tag --sort=-version:refname | head -n 1)


# if both tags are equal, there is only one tag
# => convert first tag to first commit ref
test "${first_tag}" = "${second_tag}" && first_tag=$(git rev-list --max-parents=0 HEAD)

# if first tag is empty, there is no tag yet
# => convert second tag to latest commit ref
test -z "${first_tag}" && second_tag=$(git rev-parse HEAD)


github_project_url="https://github.com/thetredev/srcds-tickrate-enabler"

release_archive=$(basename $(ls output/srcds_tickrate_enabler*.tar.gz))
release_archive_url="${github_project_url}/releases/download/${second_tag}/${release_archive}"

cat <<EOF
## Installation Instructions
1. Download the release archive at ${release_archive_url}
2. Extract it to the SRCDS game directory, e.g. \`cstrike\`
3. Restart SRCDS

The first two steps can be performed as oneliner:
\`\`\`
curl -fsSL ${release_archive_url} | tar xzf - -C <path/to/your/game_dir>
\`\`\`

## Changelog

$(git --no-pager log ${first_tag}..${second_tag} --pretty=format:"- %h %s (by %an)")

## SHA256 Checksums
\`\`\`
$(sha256sum output/addons/srcds_tickrate_enabler.vdf | sed 's|output/addons/||')
$(sha256sum output/addons/srcds_tickrate_enabler.so | sed 's|output/addons/||')
$(sha256sum output/${release_archive} | sed 's|output/||')
\`\`\`

## References
**Detailed Comparison**: [\`${first_tag}..${second_tag}\`](${github_project_url}/compare/${first_tag}..${second_tag})

EOF
