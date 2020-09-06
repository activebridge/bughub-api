# frozen_string_literal: true

class Events::BuildAttributesService < ApplicationService
  EXLCUDED_DIRECTORIES = ['vendor/', 'node_modules/']

  def call
    @params.merge(parent_id: parent_id, 'project_id' => @project.id, 'backtrace' => backtrace)
  end

  private

  def parent_id
    if @params['framework'] == Constants::Event::BROWSER_JS
      parent_id_by_message
    elsif @params['backtrace']
      project_trace && project_trace['code'] ? parent_id_by_backtrace : parent_id_by_title
    else
      parent_id_by_title
    end
  end

  def parent_id_by_backtrace
    query = 'parent_id IS NULL AND title = ? AND backtrace @> ARRAY[?]::jsonb[]'
    @project.events.where(query, @params['title'], project_trace.except(:project_error).to_json)&.first&.id
  end

  def parent_id_by_title
    @project.events.find_by(title: @params['title'], message: @params['message'], parent_id: nil)&.id
  end

  def parent_id_by_message
    @project.events.find_by(message: @params['message'], parent_id: nil)&.id
  end

  def backtrace
    @backtrace ||= begin
      return [] unless @params['backtrace']

      directory_root && trace_has_filename? ? built_backtrace : @params['backtrace']
    end
  end

  def built_backtrace
    @params['backtrace'].map do |trace|
      is_project_error = trace['filename'].include?(directory_root) && !excluded_directory?(trace['filename'])
      trace.merge(project_error: is_project_error)
    end
  end

  def directory_root
    @params.dig('server_data', 'root')
  end

  def trace_has_filename?
    @params['backtrace'].all? { |trace| trace['filename'] }
  end

  def project_trace
    backtrace.find { |trace| trace[:project_error] }
  end

  def excluded_directory?(filename)
    EXLCUDED_DIRECTORIES.any? { |directory| filename.include?(directory) }
  end
end