class Stack::BaseTokenFinder < Stack::BaseGit
  class << self
    attr_accessor :tokens_definitions
    def tokens(token_name, options={}, &block)
      @tokens_definitions ||= {}
      token_def = (@tokens_definitions[token_name] ||= {})
      token_def[:custom]           = block
      token_def[:random_threshold] = options.delete(:random_threshold)
      token_def[:proximity]        = options.delete(:proximity)
      token_def[:token_filters]    = Hash[options.map { |k, v| [k, v.is_a?(String) ? { :matcher => v } : v ] }]
    end
  end

  def is_random(str, threshold)
    last_class = nil
    num_switches = 0
    str.split('').each do |char|
      case char
      when /[a-z]/
        num_switches += 1 if last_class != /[a-z]/
        last_class = /[a-z]/
      when /[A-Z]/
        num_switches += 1 if last_class != /[A-Z]/
        last_class = /[A-Z]/
      when /[0-9]/
        num_switches += 3 if last_class != /[0-9]/
        last_class = /[0-9]/
      when /[_-]/
        num_switches += 2 if last_class != /[_-]/
        last_class = /[_-]/
      end
    end
    num_switches.to_f / str.size > threshold
  end

  def extract_tokens(env, token_options)
    filters = token_options[:token_filters]

    _regexps         = filters.values.map { |r| r[:matcher] }
    regexps          = filters.values.map { |r| Regexp.new(r[:matcher]) }
    must_have        = filters.values.map { |r| r[:must_have] }
    cannot_have      = filters.values.map { |r| r[:cannot_have] }
    line_must_have   = filters.values.map { |r| r[:line_must_have] }
    line_cannot_have = filters.values.map { |r| r[:line_cannot_have] }

    proximity = token_options[:proximity] ? token_options[:proximity] : regexps.count - 1
    lines = exec_and_capture(["grep -E -C#{proximity} -R -h '#{_regexps.first}' #{env[:src_dir]}/src",
                              *_regexps[1..-1].map { |r| "grep -E -C#{proximity} '#{r}'" }].join(" | "))

    lines.split("\n").split("--").map do |group|
      regexps.each_with_index.map do |regexp, index|
        group   = group.select   { |l| l =~ line_must_have[index]   } if line_must_have[index]
        group   = group.reject   { |l| l =~ line_cannot_have[index] } if line_cannot_have[index]
        matches = group.map      { |l| l.scan(regexp) }.flatten.compact
        matches = matches.select { |l| is_random(l, token_options[:random_threshold]) } if token_options[:random_threshold]
        matches = matches.select { |l| l =~ must_have[index]   } if must_have[index]
        matches = matches.reject { |l| l =~ cannot_have[index] } if cannot_have[index]
        break if matches.empty?
        # XXX somewhat shady .. it's possible to have two matches in the same group ..
        matches.first
      end
    end.compact.uniq
  end

  def persist_to_git(env, git)
    filter = /^src\/.*\.java$/
    env[:need_src].call(:include_filter => filter)

    all_tokens = StatsD.measure 'stack.find_tokens' do
      Hash[self.class.tokens_definitions.map do |token_name, token_options|
        if token_options[:custom]
          keys = token_options[:custom].call(env)
          next unless keys && keys.size > 0
        else
          tokens = extract_tokens(env, token_options)
          next unless tokens.size > 0

          keys = Hash[token_options[:token_filters].keys.each_with_index.map do |key, index|
            [key, tokens.map { |t| t[index] }]
          end]
        end

        [token_name, keys]
      end.compact]
    end

    git.commit do |index|
      index.add_file('tokens.json', MultiJson.dump(all_tokens, :pretty => true))
    end

    populate_app(env, all_tokens)
    @stack.call(env)
  end

  def parse_from_git(env, git)
    all_tokens = MultiJson.load(git.read_file('tokens.json'))
    populate_app(env, all_tokens)
    @stack.call(env)
  end

  def populate_app(env, all_tokens)
    total_count = 0
    all_tokens.each do |token_name, token_keys|
      app_token_name = "#{token_name}_token"

      token_keys.each do |key_name, keys|
        env[:app]["#{app_token_name}_#{key_name}".to_sym] = keys
      end
      count = token_keys.first[1].count
      total_count += count
      env[:app]["#{app_token_name}_count".to_sym] = count
    end

    env[:app][:token_count] = total_count
    env[:app][:token_type_count] = all_tokens.count
  end
end
