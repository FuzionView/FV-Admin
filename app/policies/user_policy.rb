class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.where(owner_id: user.data_providers)
      end
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def edit?
    update?
  end

  def update?
    user.administrator? # || (user.data_provider? && !record.id.in?(user.users))
  end

  def new?
    create?
  end

  def create?
    user.administrator? # ||  user.data_provider?
  end

  def destroy?
    create?
  end
end
