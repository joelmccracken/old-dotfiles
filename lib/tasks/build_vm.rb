namespace :vm do
  namespace :image do

    def use_branch
      ENV['BRANCH'] || "master"
    end

    def ssh_opts
      %Q{ -i ./misc/vagrant_private_key -o "StrictHostKeyChecking no" \
      -o "UserKnownHostsFile /dev/null" \
      -o "PasswordAuthentication yes"}
    end

    def ssh_cmd
      %Q{ssh #{ssh_opts} -p 3333 testuser@localhost}
    end

    def ssh_do command_string
      command = "#{ssh_cmd} '#{command_string}'"
      puts "running #{command}"
      cmd command
    end

    def vm_name
      "mavericks-test"
    end

    def vm_private_key_location
      "./misc/vagrant_private_key"
    end

    def mavericks_base_image_location
      "~/Documents/mavericks-base-ssh-enabled.ova"
    end

    def databag_secret_host_location
      "~/var/secrets/encrypted_data_bag_secret"
    end

    def cmd string
      system(string).tap do |success|
        if !success
          raise "Command '#{string}' exited with a non-zero status."
        end
      end
    end

    def snapshot snapshot_name
      cmd "VBoxManage snapshot #{vm_name} take #{snapshot_name}"
    end

    def ignore_errors
      begin
        yield
      rescue Exception
      end
    end

    desc "rebuild with base VM image"
    task :rebuild => [:destroy, :all] do
    end

    desc "destroy vm"
    task :destroy => [:shutdown] do
      cmd "VBoxManage unregistervm #{vm_name} --delete"
    end

    desc "shutdown VM if running"
    task :shutdown do
      ignore_errors do
        cmd "VBoxManage controlvm #{vm_name} poweroff"
      end
    end

    desc "import base image"
    task :import do
      cmd "VBoxManage import #{mavericks_base_image_location} --vsys 0 --vmname #{vm_name}"
      snapshot "after-import"
    end

    desc "start vm image"
    task :start do
      cmd "VBoxManage startvm mavericks-test"
      sleep 10 # wait for machine to boot
    end


    desc "open a ssh session on the image"
    task :ssh do
      system ssh_cmd
    end

    desc "restore to a previous snapshot; requires a 'snapshot_name=value' parameter"
    task :restore do
      name = ENV['snapshot_name']
      raise "provide snapshot_name=<val> env var" unless name
      cmd "VBoxManage snapshot #{vm_name} restore #{name}"
    end

    desc "run chef & converge the VM image"
    task :converge do
      # copy databag key
      # key must have correct perms
      cmd "chmod 0600 #{vm_private_key_location}"
      cmd "scp #{ssh_opts} -P 3333 #{databag_secret_host_location} testuser@localhost:~"

      puts "get download.sh."
      ssh_do "curl -LO https://raw.githubusercontent.com/joelmccracken/dotfiles/#{use_branch}/download.sh"

      puts "run download.sh."
      ssh_do "bash download.sh #{use_branch}"

      puts "run chef installer."
      ssh_do "cd ~/dotfiles; DOTFILES_TEST=true bin/omnibus-env ./bin/install-chef-standalone.sh"

      puts "enable sudo nopassword."
      ssh_do "echo testuser | sudo -S dotfiles/bin/toggle-sudo-nopassword on"

      # puts "run chef bootstrap."
      # ssh_do "cd dotfiles; echo testuser | sudo -S bash -c \"EDB_SECRET=~/encrypted_data_bag_secret bin/omnibus-env bin/bootstrap.sh\""

      puts "run chef bootstrap."
      ssh_do "cd dotfiles; bash -c \"EDB_SECRET=~/encrypted_data_bag_secret bin/omnibus-env bin/bootstrap.sh\""


      puts "run chef."
      ssh_do "cd dotfiles; bash -c \"EDB_SECRET=~/encrypted_data_bag_secret INTEGRATION_TEST=true bin/omnibus-env bin/converge\""

      puts "disable sudo nopassword."
      ssh_do "echo testuser | sudo -S dotfiles/bin/toggle-sudo-nopassword off"

      snapshot "after-converge"
    end

    desc "run tests in image"
    task :test do
      ssh_do "ruby dotfiles/test/*"
    end

    task :full_rerun => [:destroy, :import, :start, :converge, :test]
  end
end
