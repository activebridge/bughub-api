# frozen_string_literal: true

class API::V1::Projects::Events < Grape::API
  helpers do
    def project
      @project ||= current_user.projects.find(params[:project_id])
    end

    def event
      @event ||= project.events.find(params[:id])
    end

    def events
      @events ||= project.events.where(parent_id: nil)
                         .by_status(declared_params[:status])
                         .order(position: :asc)
                         .page(declared_params[:page])
    end

    def occurrences
      @occurrences ||= project.events
                              .by_parent(declared_params[:parent_id])
                              .order(created_at: :desc)
                              .page(declared_params[:page])
    end
  end

  namespace 'projects/:project_id' do
    resources :events do
      desc 'Returns all or parent events if status specified'
      params do
        requires :project_id, type: String
        optional :page, type: Integer, default: 1
        optional :status, type: String, values: Event.statuses.keys
      end

      get do
        EventCollectionSerializer.new(events.includes(:user)).as_json
      end

      desc 'Creates event'
      route_setting :auth, disabled: true
      params do
        requires :project_id, type: String
        requires :title, type: String
        requires :message, type: String
        optional :created_at, type: Integer
        optional :framework, type: String
        optional :environment, type: String
        optional :backtrace, type: Array
        optional :url, type: String
        optional :ip_address, type: String
        optional :headers, type: Hash
        optional :http_method, type: String
        optional :params, type: Hash
        optional :server_data, type: Hash
        optional :person_data, type: Hash
        optional :route_params, type: Hash
      end

      post do
        event = ::Events::CreateService.call(declared_params: declared_params)
        render_api(*event)
      end

      desc 'Returns event'

      get ':id' do
        render_api(event)
      end

      desc 'Returns occurrences'
      params do
        requires :project_id, type: String
        requires :parent_id, type: String
        optional :page, type: Integer, default: 1
      end

      get 'occurrences/:parent_id' do
        EventCollectionSerializer.new(occurrences).as_json
      end

      desc 'Updates event'
      params do
        requires :project_id, type: String
        requires :id, type: Integer
        requires :event, type: Hash do
          optional :status, type: String, values: Event.statuses.keys
          optional :position, type: Integer
          optional :user_id, type: Integer
        end
      end

      patch ':id' do
        event = ::Events::UpdateService.call(declared_params: declared_params, user: current_user)
        render_api(event)
      end
    end
  end
end
