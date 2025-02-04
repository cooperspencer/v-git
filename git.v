module git

import os

fn prepend_(p string, a []string) []string {
	mut copy := a.clone()
	copy.prepend(p)
	return copy
}
fn concat_(a []string, b []string) []string {
	mut copy := a.clone()
	copy << b
	return copy
}

pub struct Git {
	mut:
	dir string
	bin string
}

pub fn create(dir string, bin string) Git {
	return Git {
		dir
		bin
	}
}



fn (g Git) execute(command []string) ?string {
	res := os.execute(prepend_(g.bin, command).join(' '))
	if res.exit_code != 0 {
		return error(res.output)
	}
	return res.output
}

pub fn (mut g Git) cwd(dir string) {
	if os.is_dir(dir) {
		g.dir = dir
	} else {
		eprintln('$dir doesnt exists')
	}
	// TODO check if folder exists
}

////////

// Clone a repository into a new directory
pub fn (g Git) clone(repository string) ?string {
	return g.execute(['clone', repository])
}
pub fn (g Git) clone_to(repository string, dir string) ?string {
	return g.execute(['clone', repository, dir])
}
pub fn (g Git) clone_with_options(repository string, dir string, options string) ?string {
	return g.execute(['clone', repository, dir, options])
}

// Create an empty Git repository or reinitialize an existing one
pub fn (g Git) init() {
	g.init_with_options('')
}
pub fn (g Git) init_bare() {
	g.init_with_options('--bare')
}
pub fn (g Git) init_with_options(options string) {
	g.execute(['init', options])
}

////////

// Add file contents to the index
pub fn (g Git) add(file string) ?string {
	return g.execute(['add', file])
}
pub fn (g Git) add_multiple(files []string) ?string {
	return g.execute(prepend_('add', files))
}

// Move or rename a file, a directory, or a symlink
pub fn (g Git) mv(from string, to string) ?string {
	return g.execute(['mv', from, to])
}

// Remove files from the working tree and from the index
pub fn (g Git) rm(file string) ?string {
	return g.execute(['rm', file])
}
pub fn (g Git) rm_multiple(files []string) ?string {
	return g.execute(prepend_('rm', files))
}

pub fn (g Git) rm_keep_local(file string) ?string {
	return g.execute(['rm', '--cached', file])
}
pub fn (g Git) rm_multiple_keep_local(files []string) ?string {
	return g.execute(concat_(['rm' '--cached'], files))
}

////////

// Show changes between commits, commit and working tree, etc
pub fn (g Git) diff() {

}

// Show commit logs
pub fn (g Git) log() {

}

// Show various types of objects
pub fn (g Git) show() {

}

struct StatusRenamed {
	from string
	to string
}
struct StatusResult {
	pub mut:
	untracked []string
	ignored []string
	modified []string
	added []string
	deleted []string
	renamed []StatusRenamed
	conflicted []string

	staged []string

	ahead int
	behind int

	current string
	tracking string
}

// Show the working tree status
pub fn (g Git) status() ?StatusResult {
	output := g.execute(['status', '--porcelain', '-b', '-u']) or {
		return none
	}
	mut result := StatusResult{}
	lines := output.split_into_lines()
	for line_ in lines {
		line := line_.trim(' ')
		splitted := line.split(' ').filter(it != '')
		match splitted[0] {
			'##' {
				if splitted.index('...') != -1 {
					branch := splitted[1].split('...')
					result.current = branch[0]
					result.tracking = branch[1]
					if splitted.len >= 4 {
						shift := splitted[2].all_after('[')
						nb := splitted[3].int()
						if shift == 'behind' {
							result.behind = nb
						} else if shift == 'ahead' {
							result.ahead = nb
						}
					}
				}
			}
			'??' {
				result.untracked << splitted[1]
			}
			'!!' {
				result.ignored << splitted[1]
			}
			'M', 'MM' {
				result.modified << splitted[1]
				if line_[0] == `M` {
					result.staged << splitted[1]
				}
			}
			'A' {
				result.added << splitted[1]
				if line_[0] == `A` {
					result.staged << splitted[1]
				}
			}
			'AM' {
				result.added << splitted[1]
			}
			'D' {
				result.deleted << splitted[1]
				if line_[0] == `D` {
					result.staged << splitted[1]
				}
			}
			'R' {
				result.renamed << StatusRenamed{splitted[2], splitted[4]}
				result.staged << splitted[4]
			}
			'UU', 'AA', 'UD', 'DU', 'DD', 'AU', 'UA' {
				result.conflicted << splitted[1]
			}

			else {}
		}
	}
	return result
}

////////

// List, create, or delete branches
pub fn (g Git) branch(options string) ?string {
	return g.execute(['branch', options])
	// TODO List branches
}
pub fn (g Git) branch_delete(branch string) ?string {
	return g.execute(['branch', '-D', branch])
}

// Record changes to the repository
pub fn (g Git) commit(message string) ?string {
	return g.execute(['commit', '-m', '"$message"'])
}
pub fn (g Git) commit_with_files(message string, files []string) ?string {
	return g.execute(concat_(['commit', '-m', message], files))
}

// Join two or more development histories together
// pub fn (g Git)merge() {

// }

// Reapply commits on top of another base tip
// pub fn (g Git)rebase() {

// }

// Reset current HEAD to the specified state
// pub fn (g Git)reset() {

// }

////////

// Download objects and refs from another repository
pub fn (g Git) fetch() ?string {
	return g.execute(['fetch'])
}
pub fn (g Git) fetch_from(remote string, branch string) ?string {
	return g.execute(['fetch', remote, branch])
}

// Fetch from and integrate with another repository or a local branch
pub fn (g Git) pull() ?string {
	return g.execute(['pull'])
}
pub fn (g Git) pull_from(remote string, branch string) ?string {
	return g.execute(['pull', remote, branch])
}
pub fn (g Git) pull_with_options(remote string, branch string, options string) ?string {
	return g.execute(['pull', remote, branch, options])
}

// Update remote refs along with associated objects
pub fn (g Git) push() ?string {
	return g.execute(['push'])
}
pub fn (g Git) push_to(remote string, branch string) ?string {
	return g.execute(['push', remote, branch])
}
pub fn (g Git) push_set_upstream(remote string, branch string) ?string {
	return g.execute(['push', '--set-upstream', remote, branch])
}
pub fn (g Git) push_with_options(remote string, branch string, options string) ?string {
	return g.execute(['push', remote, branch, options])
}


// Manage set of tracked repositories
pub fn (g Git) remote_add(name string, repository string) ?string {
	return g.execute(['remote', 'add', name, repository])
}
pub fn (g Git) remote_add_with_options(name string, repository string, options string) ?string {
	return g.execute(['remote', 'add', name, repository, options])
}

pub fn (g Git) remote_remove(name string) ?string {
	return g.execute(['remote', 'remove', name])
}

// TODO Others remote
