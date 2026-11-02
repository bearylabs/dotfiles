---
name: ad-query
description: Query the company Windows Active Directory (GROUP.SIEMPELKAMP.COM) read-only from WSL with the admin account t1.rudek. Use when asked to look up AD users, groups, group memberships, computers, OUs, account status, lockouts, password expiry, or other directory data.
---

# Active Directory queries

Run queries with [`scripts/adq.sh`](scripts/adq.sh). It calls Windows PowerShell 5.1 with the RSAT `ActiveDirectory` module and injects `-Credential` (stored for `GROUP\t1.rudek`) and `-Server group.siempelkamp.com` into every `*-AD*` cmdlet. Do not pass these parameters yourself.

```bash
scripts/adq.sh 'Get-ADUser jdoe -Properties mail,Department | Select-Object Name,SamAccountName,mail,Department,Enabled'
scripts/adq.sh --json 'Get-ADGroupMember "GG-Example" | Select-Object Name,SamAccountName,objectClass'
```

Pass multi-line scripts on stdin with a quoted heredoc (`<<'PS'`) so bash does not expand `$`.

## Rules

- **Read-only.** Use only `Get-AD*`, `Search-ADAccount`, and plain PowerShell for filtering and formatting. Never modify AD; the script refuses write cmdlets. If the user asks for a change, give them the command to run themselves instead.
- Always `Select-Object` the needed properties. `-Properties *` output is huge; avoid it unless explicitly asked.
- Use `--json` when you need to process the result further; otherwise use `Format-Table -AutoSize` or `Format-List` for readability.
- Prefer server-side filters (`-Filter`, `-LDAPFilter`, `-SearchBase`) over `Where-Object` on large result sets. Add `-ResultSetSize` for broad searches.
- When a person is named instead of an account, search first (`Get-ADUser -Filter "Name -like '*Muster*'"`) and confirm ambiguous matches with the user.
- Report results concisely in the user's language. Present dates readably.

## Useful patterns

| Task | Query |
|---|---|
| User details | `Get-ADUser <sam> -Properties mail,Title,Department,Manager,LastLogonDate,PasswordLastSet,LockedOut,Enabled` |
| Group memberships of a user | `Get-ADPrincipalGroupMembership <sam> \| Select-Object Name` |
| Members of a group (nested) | `Get-ADGroupMember <group> -Recursive \| Select-Object Name,SamAccountName` |
| Locked-out accounts | `Search-ADAccount -LockedOut \| Select-Object Name,SamAccountName` |
| Password expiry | `Get-ADUser <sam> -Properties msDS-UserPasswordExpiryTimeComputed \| Select-Object Name,@{n='Expires';e={[datetime]::FromFileTime($_.'msDS-UserPasswordExpiryTimeComputed')}}` |
| Computer info | `Get-ADComputer <name> -Properties OperatingSystem,LastLogonDate,IPv4Address,Description` |
| Find groups | `Get-ADGroup -Filter "Name -like '*<term>*'" \| Select-Object Name,GroupCategory,Description` |

## Errors

- Exit 4, credential file missing: tell the user to run the printed setup command themselves (it opens an interactive password prompt). Never ask for the password in chat.
- `The user name or password is incorrect`: the stored password is stale. Do not retry (account lockout risk); ask the user to recreate the credential file.
- `Cannot find an object with identity`: the account/group name is wrong; search with `-Filter` instead.
