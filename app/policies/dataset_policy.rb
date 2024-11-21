class DatasetPolicy < ApplicationPolicy
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

  def test_ticket?
    true
  end

  def edit?
    update?
  end

  def update?
    user.administrator? || user.data_provider?
  end

  def new?
    create?
  end

  def new_wizard?
    create?
  end

  def create?
    user.administrator? || user.data_provider?
  end

  def create_step1?
    create?
  end

  def create_step2?
    create?
  end

  def create_step3?
    create?
  end

  def destroy?
    create?
  end
end
