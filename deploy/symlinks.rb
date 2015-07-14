namespace :deploy do
  namespace :symlinks do
    task :additional, except: { no_release: true } do
      symlinks = {}
      symlinks["/srv/repos"]   = "repos"
      symlinks["/srv/scratch"] = "scratch"
      symlinks["/srv/matches"] = "matches"
      symlinks["/srv/s3"]      = "s3"
      symlinks["#{shared_path}/nodes.yml"] = "config/nodes.yml"
      symlinks["#{shared_path}/p27env"] = "p27env"
      symlinks["#{shared_path}/s3_creds.rb"] = "config/initializers/00_s3_creds.rb"

      cmd = []
      symlinks.each do |src, dst|
        cmd << "rm -rf #{release_path}/#{dst}"
        cmd << "ln -Tfs #{src} #{release_path}/#{dst}"
      end

      run cmd.join(' && ')
    end
  end

  task :adjust_permissions do
    run "chown -R deploy: #{shared_path}"
  end
end

after "deploy:create_symlink", "deploy:symlinks:additional"
after "deploy:symlinks:additional", "deploy:adjust_permissions"
