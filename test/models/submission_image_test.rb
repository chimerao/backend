require 'test_helper'

class SubmissionImageTest < ActiveSupport::TestCase

  setup do
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'FLCL.jpg')
  end

  test "created a submission with an image should have its type set to SubmissionImage" do
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    create_options = {
      profile: profiles(:dragon_profile_1),
      file: image,
      title: 'FLCL',
      description: 'A great series'
    }
    assert_difference 'Submission.count' do
      @new_submission = Submission.create(create_options)
    end

    assert 'SubmissionImage', @new_submission.type
  end

end