require 'test_helper'

class EssaysControllerTest < ActionController::TestCase
  setup do
    @essay = essays(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:essays)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create essay" do
    assert_difference('Essay.count') do
      post :create, essay: { body: @essay.body, title: @essay.title }
    end

    assert_redirected_to essay_path(assigns(:essay))
  end

  test "should show essay" do
    get :show, id: @essay
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @essay
    assert_response :success
  end

  test "should update essay" do
    patch :update, id: @essay, essay: { body: @essay.body, title: @essay.title }
    assert_redirected_to essay_path(assigns(:essay))
  end

  test "should destroy essay" do
    assert_difference('Essay.count', -1) do
      delete :destroy, id: @essay
    end

    assert_redirected_to essays_path
  end
end
