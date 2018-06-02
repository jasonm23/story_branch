class StoryBranch::GitUtils
  def self.g
    Git.open '.'
  end

  def self.is_existing_branch? name
    branch_names.each do |n|
      if Levenshtein.distance(n, name) < 3
        return true
      end
      existing_branch_name = n.match(/(.*)(-[1-9][0-9]+$)/)
      if existing_branch_name
        levenshtein_distance = Levenshtein.distance existing_branch_name[1], name
        if levenshtein_distance < 3
          return true
        end
      end
    end
    return false
  end

  def self.is_existing_story? id
    branch_names.each do |n|
      branch_id = n.match(/-[1-9][0-9]+$/)
      if branch_id
        if branch_id.to_s == "-#{id}"
          return true
        end
      end
    end
    false
  end

  def self.branch_names
    g.branches.map(&:name)
  end

  def self.current_branch
    g.current_branch
  end

  def self.current_story
    current_branch.match(/(.*)-(\d+$)/)
  end

  def self.current_branch_story_parts
    matches = current_story
    if matches.length == 3
      { title: matches[1], id: matches[2] }
    else
      nil
    end
  end

  def self.create_branch name
    g.branch(name).create
    g.branch(name).checkout
  end

  def self.status_collect status, regex
    status.select{|e|
      e.match(regex)
    }.map{|e|
      e.match(regex)[1]
    }
  end

  def self.status
    modified_rx  = /^ M (.*)/
    untracked_rx = /^\?\? (.*)/
    staged_rx    = /^M  (.*)/
    added_rx     = /^A  (.*)/
    status = g.lib.send(:command, 'status', '-s').lines
    return nil if status.length == 0
    {
      modified:  status_collect(status, modified_rx),
      untracked: status_collect(status, untracked_rx),
      added:     status_collect(status, added_rx),
      staged:    status_collect(status, staged_rx)
    }
  end

  def self.has_status? state
    return false unless status
    status[state].length > 0
  end

  def self.commit message
    g.commit(message)
  end

end