#!/bin/sh

step_commits=$(git log --grep="^feat: step" --oneline)

echo "Remove all existing tags..."
git tag | xargs -r git tag -d

echo "$step_commits" | while IFS= read -r line; do
  # Extract the commit hash
  commit_hash=$(echo "$line" | awk '{print $1}')
  # Extract the name of the future tag
  tag_name=$(echo "$line" | cut -d' ' -f2- | sed -e 's/^feat: //')

  echo "Creating tag for commit $commit_hash with name $tag_name"
  git tag -a "$tag_name" -m "$tag_name" "$commit_hash"
done
