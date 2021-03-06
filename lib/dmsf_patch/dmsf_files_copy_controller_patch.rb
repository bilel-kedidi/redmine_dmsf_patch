module DmsfPatch
  module DmsfFilesCopyControllerPatch
    module InstanceMethods

      # Returns a link for adding a new subtask to the given issue
      def move_with_js
        respond_to do |format|
          format.html{
           move_without_js
          }
          format.js{
            @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
            unless @target_project && User.current.allowed_to?(:file_manipulation, @target_project) && User.current.allowed_to?(:file_manipulation, @project)
              error =  'Not allowed'
              @json= {success: false, error_msg: error}
              return
            end
            @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
            if @target_folder && @target_folder.project != @target_project
              error =  l(:error_entry_project_does_not_match_current_project)
              @json= {success: false, error_msg: error}
              return
            end
            if (@target_folder && @target_folder == @file.dmsf_folder) ||
                (@target_folder.nil? && @file.dmsf_folder.nil? && @target_project == @file.project)
              error = l(:error_target_folder_same)
              @json= {success: false, error_msg: error}
              return
            end

            unless @file.move_to(@target_project, @target_folder)
              error = "#{l(:error_file_cannot_be_moved)}: #{@file.errors.full_messages.join(', ')}"
              @json= {success: false, error_msg: error}
              return
            end

            @json= {success: true}
          }
        end

      end
    end


    def self.included(receiver)
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        unloadable
        alias_method_chain :move, :js
      end
    end
  end


end
