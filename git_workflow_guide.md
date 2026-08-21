# Team Git Workflow & Collaboration Guide

This guide outlines our team's official Git workflow. Follow these steps for every feature, bug fix, or change to keep our codebase clean, conflict-free, and stable.

---

## 🚀 The Daily Workflow Cycle

Follow this exact loop every time you start working on something new. Never code directly on the `main` branch.

```
[Remote main] ---> 1. git pull ---> [Local main] ---> 2. git checkout -b [Branch]
                                                                  |
[Remote main] <--- 5. Merge PR <--- 4. git push <--- 3. Commit  <--+
```

### Step 1: Sync Your Local Machine

Before starting any new task, make sure your computer has the absolute latest changes from the team.

```bash
# Switch to the main branch
git checkout main

# Pull the latest changes from GitHub
git pull origin main
```

### Step 2: Create a Feature Branch

Create a separate, temporary branch for your specific task. Name it descriptively (e.g., `login-page`, `bugfix-navbar`).

```bash
# Create and switch to your new branch
git checkout -b <branch-name>
```

### Step 3: Code, Stage, and Commit

Write your code and save your progress locally. Keep your commits small and focused.

```bash
# Check which files you changed
git status

# Stage all your changes for commit
git add .

# Commit with a clear, descriptive message
git commit -m "Add short description of what you changed"
```

### Step 4: Push to GitHub

Upload your temporary branch to our shared GitHub repository.

```bash
git push origin <branch-name>
```

### Step 5: Open a Pull Request (PR) & Merge

1. Go to our project page on GitHub.
2. Click the green **"Compare & pull request"** button that appears.
3. Describe your changes and request a team member to review it.
4. Once reviewed and approved, click **"Merge pull request"** and delete the branch on GitHub.

---

## 🧹 Post-Merge Cleanup (only after branch is merged)

Merging on GitHub does **not** delete the branch from your local computer. Run these commands to clean up your workspace:

```bash
# 1. Switch back to your main branch
git checkout main

# 2. Tell your local Git to recognize that the branch was deleted on GitHub
git fetch --prune

# 3. Safely delete the local branch from your computer
git branch -d <branch-name>
```

---

## ⚠️ How to Handle Merge Conflicts

If you and a teammate edit the same line of the same file, GitHub will block your merge. Follow these steps to resolve it safely:

### 1. Pull Main into Your Branch

While standing on your feature branch, pull the updated `main` branch into it:

```bash
git pull origin main
```

Git will warn you: `CONFLICT (content): Merge conflict in <filename>`.

### 2. Open and Fix the File Manually

Open the conflicted file in your text editor (e.g., VS Code). Look for the conflict markers:

```text
<<<<<<< HEAD
Teammate's code that is already on the main branch
=======
Your new code that you are trying to merge
>>>>>>> <branch-name>
```

* Decide which code to keep (or combine them).
* **Delete** the marker lines (`<<<<<<<`, `=======`, `>>>>>>>`).
* Save the file.

### 3. Commit and Push the Fix

```bash
# Stage the resolved file
git add <filename>

# Commit the conflict resolution
git commit -m "Fix merge conflict with main"

# Push back up to your Pull Request
git push origin <branch-name>
```

The warning on GitHub will disappear, and you can now safely merge!

---

## 💡 Pro-Tips for Success

* **Keep tasks small:** Don't build massive features all at once. Break them down into smaller branches and merge often.
* **Talk to each other:** Let teammates know what files or components you are modifying to prevent overlapping work.
* **Protect the Main branch:** Ensure repository settings require a Pull Request before anyone can merge into `main`.
