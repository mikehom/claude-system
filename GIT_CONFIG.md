# Git Configuration for Claude System

**Repository**: https://github.com/juanandresgs/claude-system  
**Branch**: main  
**Visibility**: Private  
**Setup Date**: 2025-09-02

## Configuration Settings

### Repository Configuration
- **GPG Signing**: Disabled (`commit.gpgsign = false`)
- **Push Default**: Simple (`push.default = simple`)
- **Default Branch**: main
- **User**: Claude System <claude@anthropic.com>

### Branch Tracking
- **Local Branch**: main
- **Remote Branch**: origin/main
- **Upstream**: origin/main

## Repository Structure

### Tracked Files
- **Core Framework**: All .md files (CLAUDE.md, COMMANDS.md, FLAGS.md, etc.)
- **Scripts**: scripts/ directory with utility scripts
- **Configuration**: settings.json, .superclaude-metadata.json
- **Engineering Tools**: engineering/ directory with deployment scripts
- **Commands**: commands/ directory with command definitions
- **Plugins**: plugins/ directory with plugin configurations

### Excluded Files (.gitignore)
- **Data Directories**: projects/ (100MB), todos/, shell-snapshots/, backups/
- **Runtime Data**: history/, reports/, metrics/, statsig/
- **Local Settings**: settings.local.json
- **Temporary Files**: *.tmp, *.log, .DS_Store

## Maintenance Procedures

### Daily Operations
```bash
# Check status
cd ~/.claude && git status

# Add new files
git add .

# Commit changes
git commit -m "Update: description of changes

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push
```

### Backup Verification
The simple backup system continues to operate independently of Git:
- **Schedule**: Daily/weekly/monthly via LaunchAgent
- **Location**: ~/.claude/backups/ (excluded from Git)
- **Purpose**: Conversation files and runtime data preservation

### Branch Protection
- **Main Branch**: Protected, all changes should be reviewed
- **Direct Pushes**: Allowed for system owner
- **History**: Preserve all commit history for framework evolution

## Integration with Claude Memory

This configuration is saved to Claude's institutional memory:
- **Repository Location**: ~/.claude (Git repository)
- **Private Repository**: https://github.com/juanandresgs/claude-system
- **GPG Signing**: Always disabled for this repository
- **Commit Convention**: Include Claude Code attribution

## Security Considerations

### Data Protection
- **Sensitive Data**: Excluded via .gitignore (conversation files, local settings)
- **Public Exposure**: Repository is private, framework patterns are safe to share
- **Access Control**: Only repository owner has access

### Backup Strategy
- **Git Repository**: Framework and configuration files only
- **Local Backups**: Conversation data and runtime state (excluded from Git)
- **Redundancy**: Both Git history and local backup system active

## Future Considerations

### Repository Evolution
- Framework updates and enhancements tracked via Git
- Pattern extraction results may be added to version control
- Documentation updates automatically committed

### Collaboration
- Repository structure supports future team collaboration
- Private visibility allows controlled sharing when needed
- Clear separation between framework (tracked) and data (local)

---

*This Git configuration ensures proper version control for the Claude System framework while protecting sensitive conversation data and maintaining clean separation between code and data.*