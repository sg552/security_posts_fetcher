Rails.application.routes.draw do
   root "blogs#index"
   resources :blogs do
     collection do
     end
   end
end
