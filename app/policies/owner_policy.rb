class OwnerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.where(id: user.data_providers)
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
    user.administrator?
  end

  def new?
    create?
  end

  def create?
    user.administrator?
  end

  def destroy?
    create?
  end
end
