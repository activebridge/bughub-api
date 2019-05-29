# frozen_string_literal: true

Rails.application.routes.draw do
  mount API::Base, at: '/api'
  mount_devise_token_auth_for 'User', at: '/auth', controllers: {
    omniauth_callbacks: 'omniauth_callbacks'
  }
end
