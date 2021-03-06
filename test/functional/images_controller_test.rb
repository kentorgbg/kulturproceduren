require_relative '../test_helper'

class ImagesControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @user = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = @user.id
  end

  test "index, wrong parameters" do
    get :index
    assert_redirected_to root_url()
    assert_equal         "Felaktigt anrop.", flash[:error]
  end
  test "index, culture provider" do
    culture_provider = create(:culture_provider)
    images           = create_list(:image, 2, culture_provider: culture_provider)

    get :index, culture_provider_id: culture_provider.id

    assert_response :success
    assert          assigns(:image).new_record?
    assert_equal    culture_provider, assigns(:image).culture_provider
    assert_equal    images,           assigns(:images)
  end
  test "index, event" do
    event  = create(:event)
    images = create_list(:image, 2, event: event)

    get :index, event_id: event.id

    assert_response :success
    assert          assigns(:image).new_record?
    assert_equal    event,  assigns(:image).event
    assert_equal    images, assigns(:images)
  end

  test "set main" do
    culture_provider = create(:culture_provider)
    images           = create_list(:image, 2, culture_provider: culture_provider)

    culture_provider.main_image = images.first
    culture_provider.save!

    get :set_main, culture_provider_id: culture_provider.id, id: images.last.id
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         images.last, CultureProvider.find(culture_provider.id).main_image(true)
  end

  test "create, wrong parameters" do
    post :create
    assert_redirected_to root_url()
    assert_equal         "Felaktigt anrop.", flash[:error]
  end
  test "create, culture provider" do

    file = fixture_file_upload("image.jpg", "image/jpeg", true)

    culture_provider = create(:culture_provider)

    # Invalid
    post :create, culture_provider_id: culture_provider.id, image: { file: file, description: "" }
    assert_response :success
    assert_template "images/index"
    assert          !assigns(:image).valid?

    # Valid
    post :create, culture_provider_id: culture_provider.id, image: { file: file, description: "foo" }

    image = Image.last
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         "Bilden laddades upp.", flash[:notice]
    assert_equal         culture_provider,       image.culture_provider
    assert_equal         "foo",                  image.description

    # Cleanup, removes the uploaded file
    image.destroy
  end
  test "create, event" do
    file = fixture_file_upload("image.jpg", "image/jpeg", true)

    event = create(:event)

    # Invalid
    post :create, event_id: event.id, image: { file: file, description: "" }
    assert_response :success
    assert_template "images/index"
    assert          !assigns(:image).valid?

    # Valid
    post :create, event_id: event.id, image: { file: file, description: "foo" }

    image = Image.last
    assert_redirected_to event_images_url(event)
    assert_equal         "Bilden laddades upp.", flash[:notice]
    assert_equal         event,                  image.event
    assert_equal         "foo",                  image.description

    # Cleanup, removes the uploaded file
    image.destroy
  end

  test "destroy, culture provider" do
    File.stubs(:delete)

    culture_provider = create(:culture_provider)
    image            = create(:image, culture_provider: culture_provider, event: nil)
    main_image       = create(:image, culture_provider: culture_provider, event: nil)

    culture_provider.main_image = main_image
    culture_provider.save!

    delete :destroy, id: image.id
    assert_redirected_to culture_provider_images_url(culture_provider)
    assert_equal         "Bilden togs bort", flash[:notice]
    assert_nil           Image.where(id: image.id).first
    assert_equal         main_image, CultureProvider.find(culture_provider.id).main_image

    delete :destroy, id: main_image.id
    assert_nil CultureProvider.find(culture_provider.id).main_image
  end
  test "destroy, event" do
    File.stubs(:delete)
    event = create(:event)
    image = create(:image, event: event, culture_provider: nil)

    delete :destroy, id: image.id
    assert_redirected_to event_images_url(event)
    assert_equal         "Bilden togs bort", flash[:notice]
    assert_nil           Image.where(id: image.id).first
  end
end
