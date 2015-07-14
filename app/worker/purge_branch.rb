class PurgeBranch
  include NodeWorker

  def node_perform(app_id, branch)
    Timeout.timeout(1.minute) do
      Stack.purge_branch(:app_id => app_id, :purge_branch => branch)
    end
  end

  def self.purge_all(branch)
    App.all.each { |app_id| perform_async_on_node(Node.get_node_for_app(app_id), app_id, branch) }.count
  end
end
