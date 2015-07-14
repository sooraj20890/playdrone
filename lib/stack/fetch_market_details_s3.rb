class Stack::FetchMarketDetailsS3 < Stack::BaseS3
  use_fs :bucket_name     => ->(env){ "playdrone-metadata-#{env[:crawled_at]}-#{App.bucket_hash(env[:app_id])}" },
         :bucket_metadata => {:mediatype => :software, :collection => 'playdrone-metadata'},
         :file_name       => ->(env){ "#{env[:app_id]}.json" }

  def persist_to_s3(env, s3)
    if env[:crawled_at] != Date.today
      instantiate_app(env, :use_previous_data)
      @stack.call(env)
      return
    end

    begin
      app_details = Market.details(env[:app_id])

      if Rails.env.production?
        App.discovered_apps(app_details.related_app_ids)
      end

      instantiate_app(env, app_details.raw_app)

      raise "No version code. Accounts overloaded?" unless env[:app].version_code

      StatsD.measure 'stack.persist_market_details' do
        s3.write(MultiJson.dump(app_details.raw_app, :pretty => true))
      end

      @stack.call(env)
    rescue Market::NotFound
      instantiate_app(env, nil)
      s3.write(MultiJson.dump({:app_id => env[:app_id], :not_found => true}))
      # Chain halts
    end
  end

  def parse_from_s3(env, s3)
    metadata = MultiJson.load(s3.read, :symbolize_keys => true)

    if metadata[:not_found]
      instantiate_app(env, nil)
    else
      instantiate_app(env, metadata)
      @stack.call(env)
    end
  end

  private

  def populate_previous_app(env)
    env[:number_of_404_days] = 0
    ((env[:crawled_at] - 5.days) ... env[:crawled_at]).to_a.reverse.each do |day|
      raw_metadata = nil

      bucket_name =  "playdrone-metadata-#{day}-#{App.bucket_hash(env[:app_id])}"
      file_name = "#{env[:app_id]}.json"

      fs = FS.new(:bucket_name => bucket_name, :file_name => file_name)
      next unless fs.object_exists?
      raw_metadata = fs.read

      metadata = MultiJson.load(raw_metadata, :symbolize_keys => true)
      if metadata[:not_found]
        env[:number_of_404_days] += 1
        next
      end

      env[:previous_app_raw] = metadata
      env[:previous_app] = App.from_market(metadata)
      break
    end
  end

  def instantiate_app(env, raw_app, options={})
    populate_previous_app(env)

    if raw_app == :use_previous_data
      raw_app = env[:previous_app_raw]
    end

    if raw_app
      env[:app] = App.from_market(raw_app)
    else
      if env[:previous_app]
        env[:app] = env[:previous_app].dup
      else
        env[:app] = App.new.tap { |app| app._id = env[:app_id] }
      end
      env[:app_not_found] = true
    end

    env[:app].crawled_at = env[:crawled_at]

    if env[:previous_app]
      env[:app].market_released = false
      env[:app].apk_updated     = raw_app ? (env[:previous_app].version_code != env[:app].version_code) : false
      env[:app].market_removed  = !raw_app
    else
      env[:app].market_released = true
      env[:app].apk_updated     = false
      env[:app].market_removed  = false
    end
  end
end
