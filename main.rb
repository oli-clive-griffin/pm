# very simple cli task manager made for managing prioritisation of projects

require 'json'


class Task
  attr_reader :title, :status

  def initialize title, status
    @title = title
    @status = status
  end

  def format
    "#{@title}, #{@status}"
  end

  def as_hash
    {
      'title' => @title,
      'status' => @status,
    }
  end

  def to_json(*options)
    as_hash.to_json(*options)
  end

  def self.from_hash hash
    Task.new(hash['title'], hash['status'])
  end
end

class Project
  attr_reader :title, :priority

  def initialize title, priority, tasks
    @title = title
    @priority = priority
    @tasks = tasks
  end

  def format
    "#{@title}, p#{@priority}" + @tasks.map { |task| "\n   - #{task.format}" }.join
  end
  
  def as_hash
    {
      'title' => @title,
      'priority' => @priority,
      'tasks' => @tasks.map { |task| task.as_hash },
    }
  end

  def to_json(*options)
    as_hash.to_json(*options)
  end

  def self.from_hash hash
    Project.new(hash['title'], hash['priority'], hash['tasks'].map { |task| Task.from_hash(task) })
  end
end

class ProjectList
  attr_reader :projects

  def initialize projects
    @projects = projects || []
  end

  def format
    out = ''
    out += "Projects:\n"
    @projects.each_with_index do |project, index|
      out += "#{index + 1}. #{project.format}\n"
    end
    out
  end

  def to_json(*options)
    @projects.map { |item| item.as_hash }.to_json(*options)
  end

  def self.from_json_arr arr
    ProjectList.new arr.map { |item| Project.from_hash(item) }
  end
end


class CLI
  def ask question
    puts question
    gets.chomp
  end

  def pick question, options
    while true
      puts "#{question}: "
      options.each_with_index do |option, index| 
        puts "#{index + 1}. #{option}"
      end
      input = gets.chomp
      if input.to_i > 0 && input.to_i <= options.length
        return input.to_i - 1
      end
      puts "Invalid input\n\n"
    end
  end
end


class App
  def initialize cli, file
    @file = file || "tasks.json"
    @cli = cli
    @project_list = ProjectList.new nil
    get_existing_list
  end

  def get_existing_list
    if File.exist?(@file)
      @project_list = ProjectList.from_json_arr(JSON.parse(File.read(@file)))
    end
  end
  
  def run
    begin
      while true
        actions = ["Add project", "List projects", "Delete project", "Exit"]
        action_idx = @cli.pick("What do you want to do?", actions)
        
        case action_idx
        when 0
          add_project
        when 1
          list_projects
        when 2
          delete_project
        when 3
          break
        end
      end
    rescue Interrupt
      puts "\n\n saving and exiting\n\n"
      File.write(@file, @project_list.to_json)
    end
  end

  def add_project
    title = @cli.ask "Enter project title: "
    priority = @cli.ask("Enter project priority: ").to_i
    tasks = []
    while true
      task_title = @cli.ask("Enter task title: ")
      task_status = @cli.ask("Enter task status: ")
      tasks.push(Task.new(task_title, task_status))
      if @cli.ask("Add another task? (y/n): ") == "n"
        break
      end
    end
    @project_list.projects.push(Project.new(title, priority, tasks))
  end

  def list_projects
    puts "\n\n#{puts @project_list.format}\n\n"
  end

  def delete_project
    # list_projects
    project_idx = @cli.pick "Which project do you want to delete?", @project_list.projects.map(&:title)
    proj = @project_list.projects[project_idx]
    @project_list.projects.delete_at(project_idx)
    puts "Project deleted: #{proj.title}"
  end
end

App.new(CLI.new, nil).run