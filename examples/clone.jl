# LibGit2.jl "clone" example - shows how to use the clone API
#
# Written by the LibGit2.jl contributors, based on the libgit2 examples.
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software. If not, see
# <http://creativecommons.org/publicdomain/zero/1.0/>.

using LibGit2
using ArgParse

# This example demonstrates the use of the LibGit2.jl clone APIs
# emulating the command `git clone` and printing the progress of
# the clone process and of the checkout

# from the git-clone man page:
# Clones a repository into a newly created directory, creates remote-tracking
# branches for each branch in the cloned repository (visible using git branch -r),
# and creates and checks out an initial branch that is forked from the cloned 
# repository's currently active branch.

function parse_commandline()
    settings = ArgParseSettings(autofix_names=true)
    @add_arg_table settings begin
        "repo-url" 
        help = "repo url"
        required = true
        
        "directory"
        help = ""
    end
    args = parse_args(settings)
    # Convert keys to symbol
    #a rgs = {symbol(k)=>v for (k,v) in args}
    # prune "nothing" values just for debug and to work in a clearer space
    for (k,v) in args
        v == nothing && delete!(args,k)
    end
    return args
end


function clone(repo_url::String, dest_dir::String="")
    # fetch and checkout head with progress indication
    # FIXME logic
    if isempty(dest_dir)
        dest_dir = dest_dir * basename(splitext(repo_url)[1])
        mkdir(dest_dir)
    end

    println(dest_dir)
    info("dest dir generated: $dest_dir")

    total_objects = indexed_objects = received_objects = received_bytes = 0
    repo = repo_clone(repo_url, dest_dir, {
        :callbacks => {
          :transfer_progress => (args...) -> begin
            total_objects, indexed_objects, received_objects, received_bytes = args
            perc = int(received_objects / total_objects * 100.0)
            print("\rReceiving objects: $perc% ($received_objects/$total_objects) $(pretty_size(received_bytes))")
            end
          }
        }
      )
    println(", done.")

    path = completed_steps = total_steps = payload = 0
    checkout_head!(repo,
      {:strategy => :safe_create,
      :progress => (args...) -> begin
        path, completed_steps, total_steps = args
        print("\rUnpacking files: $completed_steps/$total_steps")
      end
      }
    )

    println(", done.")
    return repo
end

function pretty_sizen(n)
    # Assuming n is in bytes
    c = log2(n) / 10
    val = n / 1024^floor(c)
    c < 1      && return @sprintf("%i B",val)
    1 <= c < 2 && return @sprintf("%.2f KiB",val)
    2 <= c < 3 && return @sprintf("%.2f MiB",val)
    3 <= c     && return @sprintf("%.2f GiB",val)
end

function main()
    opts = parse_commandline()
    haskey(opts, "directory") ? clone(opts["repo_url"], opts["directory"]) : clone(opts["repo_url"])
end

main()
