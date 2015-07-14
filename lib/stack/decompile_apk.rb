require 'fileutils'

class Stack::DecompileApk < Stack::BaseGit
  class DecompilationError < RuntimeError; end

  use_git :branch => :src

  def persist_to_git(env, git)
    return unless env[:app].free
    return if env[:app_id].in? %w(com.snowdream.find.sexygirls
                                  com.planemo.mudras
                                  com.snowdream.find.superstars) # decompiler gets stuck on these ones

    env[:need_apk].call
    output = StatsD.measure 'stack.decompile' do
      exec_and_capture('script/decompile', env[:scratch], env[:apk_path].basename)
    end
    env[:app].decompiled = $?.success?

    unless env[:app].decompiled
      if output =~ /mv: cannot stat .*smali.: No such file or directory/
        # No sources, an application with just resources (themes)
        git.commit :message => "No sources (Theme pack?)"
        git.set_head
        return
      end

      if output =~ /fatal error/                     ||
         output =~ /OutOfMemoryError/                ||
         output =~ /StackOverflowError/              ||
         output =~ /ClassCastException/              ||
         output =~ /NullPointerException/            ||
         output =~ /OutOfBoundException/             ||
         output =~ /IndexOutOfBoundsException/       ||
         output =~ /DexException/                    ||
         output =~ /dexlib\.Code\.Instruction/       ||
         output =~ /File name too long/              ||
         output =~ /Could not decode/                ||
         output =~ /Segmentation fault/              ||
         output =~ /androlib\.res\.decoder/          ||
         output =~ /glibc detected/                  ||
         output =~ /Can't find framework resources/  ||
         output =~ /UndefinedResObject/              ||
         output =~ /Killed/

        # Too bad, the decompiler sucks
        Rails.logger.info "Cannot decompile #{env[:app_id]}"
        Rails.logger.info output

        git.commit :message => "Failed to decompile"
        git.set_head
        return
      end

      raise DecompilationError.new(output)
    end

    env[:src_git] = git
    env[:need_src] = ->(_){}
    env[:src_dir] = env[:scratch].join('src')

    StatsD.measure 'stack.persist_src' do
      git.commit do |index|
        index.add_dir(env[:src_dir])
      end
      git.set_head
    end

    env[:need_git_gc] = true

    @stack.call(env)
  end

  def parse_from_git(env, git)
    env[:app].decompiled = git.committed_tree.count > 0
    return unless env[:app].decompiled

    env[:src_git] = git
    env[:need_src] = lambda do |options|
      env[:src_dir] = env[:scratch].join('src')
      FileUtils.mkpath(env[:src_dir])

      git.read_files(options) do |filename, content|
        path = env[:src_dir].join(filename)
        if content
          File.open(path, 'wb') { |f| f.write(content) }
        else
          FileUtils.mkpath(path)
        end
      end
    end

    @stack.call(env)
  end
end
