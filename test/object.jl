# create a repo with a README file
cleanup_dir(p) = begin
    if isdir(p)
        run(`rm -f -R $p`)
    end
end

# ------------------------------------
# Tests adapted from Git2Go Library
# ------------------------------------
test_path = joinpath(pwd(), "testrepo")
try
    repo = create_test_repo(test_path)
    cid, tid = seed_test_repo(repo)

    c1 = lookup(GitCommit, repo, cid)
    c2 = lookup_commit(repo, cid)
    @test c1 == c2
    @test git_otype(c1) == 1#api.OBJ_COMMIT
    @test git_otype(c2) == 1#api.OBJ_COMMIT
    
    # test repo has one commit
    ctree = GitTree(c1)
    @test length(ctree) == 1

    t = lookup(GitTree, repo, tid)
    @test Oid(t) == tid
    @test isa(t, GitTree)
    entry = entry_byname(t, "README")
    @test entry != nothing
    
    @test filemode(entry) == 33188 #api.FILEMODE_BLOB
    obj = lookup(repo, Oid(t))
    @test isa(obj, GitTree)

    obj = repo_revparse_single(repo, "HEAD")
    @test isa(obj, GitCommit)
    @test Oid(obj) == cid
    
    obj = repo_revparse_single(repo, "HEAD^{tree}")
    @test isa(obj, GitTree)
    @test Oid(obj) == Oid(t)
catch err
    rethrow(err)
finally 
    cleanup_dir(test_path)
end

# -----------------------------------------
# Tests adapted from Ruby's Rugged Library
# -----------------------------------------
@with_repo_access begin
   #@test repo_path(test_repo) == test_repo_path
   
   begin # lookup any object type 
       blob = test_repo[Oid("fa49b077972391ad58037050f2a75f74e3671e92")]
       @test isa(blob, GitBlob)

       commit = test_repo[Oid("8496071c1b46c854b31185ea97743be6a8774479")]
       @test isa(commit, GitCommit)
        
       tag = test_repo[Oid("0c37a5391bbff43c37f0d0371823a5509eed5b1d")]
       @test isa(tag, GitTag)

       tree = test_repo[Oid("c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b")]
       @test isa(tree, GitTree)
   end

   begin # test_fail_to_lookup_inexistant_object 
       @test_throws LibGitError{:Odb,:NotFound} test_repo[Oid("a496071c1b46c854b31185ea97743be6a8774479")]
   end

   begin # test_lookup_object
        obj = test_repo[Oid("8496071c1b46c854b31185ea97743be6a8774479")]
        @test isa(obj, GitCommit)
        @test Oid("8496071c1b46c854b31185ea97743be6a8774479") == Oid(obj)
   end

   begin # test_objects_are_the_same
        obj1 = test_repo[Oid("8496071c1b46c854b31185ea97743be6a8774479")]
        obj2 = test_repo[Oid("8496071c1b46c854b31185ea97743be6a8774479")]
        @test obj1 == obj2
   end
  
   begin # test_read_raw_data
        obj = test_repo[Oid("8496071c1b46c854b31185ea97743be6a8774479")]
        @test isa(raw(obj), OdbObject)
   end
   
   begin # test_lookup_by_rev
        obj = rev_parse(test_repo, "v1.0")
        @test Oid(obj) == Oid("0c37a5391bbff43c37f0d0371823a5509eed5b1d")
        obj = rev_parse(test_repo, "v1.0^1")
        @test Oid(obj) == Oid("8496071c1b46c854b31185ea97743be6a8774479")
   end 
   
   begin # test_lookup_oid_by_rev
       o = rev_parse_oid(test_repo, "v1.0")
       @test o == Oid("0c37a5391bbff43c37f0d0371823a5509eed5b1d")
       o = rev_parse_oid(test_repo, "v1.0^1")
       @test o == Oid("8496071c1b46c854b31185ea97743be6a8774479")
   end
end
