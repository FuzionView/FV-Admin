class SystemOperatorPolicy < ApplicationPolicy
  def index?
    user.administrator?
  end

  def show?
    update?
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
