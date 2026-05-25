# Git Setup

You need Git identity before making meaningful commits.

## Minimum local setup

Run:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

This sets commit author identity on this machine.

## Do you need a Git profile?

Yes, if you want to:

- push to GitHub, GitLab, or Azure DevOps
- collaborate with other people through a hosted remote
- open pull requests
- use issue tracking tied to your account

No, if you only want local version control for now.

## Recommended order

1. Create a GitHub account or use your company-approved Git host.
2. Set local Git identity on this machine.
3. Create an empty remote repository.
4. Add the remote.
5. Push the initial branch.

## Notes for this repo

- do not commit credentials
- keep real tenant config in ignored local files
- sanitize any customer examples before adding them under `examples/`
