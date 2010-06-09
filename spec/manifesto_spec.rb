require File.dirname(__FILE__) + '/spec_helper'

describe Manifesto do
  describe ".validate_options" do
    it "should raise ArgumentError if directory is not a real directory" do
      expect{ Manifesto.validate_options('', false) }.to raise_error(ArgumentError)
    end

    it "should raise ArgumentError if compute_hash is not a boolean" do
      expect{ Manifesto.validate_options('.', nil) }.to raise_error(ArgumentError)
    end
  end

  describe ".cache" do
    before(:each) do
      Manifesto.stub!(:validate_options).and_return(true)
    end

    it "should validate the options" do
      Manifesto.should_receive(:validate_options).and_return(true)
      Manifesto.cache
    end

    context "when default directory" do
      it "should get file paths from the default directory" do
        Manifesto.should_receive(:get_file_paths).with('./public').and_return([])
        Manifesto.cache
      end
    end

    context "when directory is specified" do
      it "should get file path from within the specified directory" do
        Manifesto.should_receive(:get_file_paths).with('./mobile').and_return([])
        Manifesto.cache(:directory => './mobile')
      end
    end

    context "when there are no files in the directory" do
      before(:each) do
        Manifesto.stub!(:get_file_paths).and_return([])
      end

      it "should not compute hash" do
        Manifesto.should_receive(:compute_file_contents_hash).never
        Manifesto.cache
      end
    end

    context "when there are files in the directories" do
      it "should check the file" do
        File.should_receive(:file?)
        Manifesto.cache
      end

      context "and path is for the directory or symlink" do
        before(:each) do
          Manifesto.stub!(:get_file_paths).and_return(['public/dir1', 'public/symlink'])
          File.stub!(:file?).and_return(false)
        end

        it "should not compute hash" do
          Manifesto.should_receive(:compute_file_contents_hash).never
          Manifesto.cache
        end

        it "should not normalize the path" do
          Manifesto.should_receive(:normalize_path).never
          Manifesto.cache
        end
      end

      context "and path is for the hidden file" do
        before(:each) do
          Manifesto.stub!(:get_file_paths).and_return(['public/.hiddenfile'])
          File.stub!(:file?).and_return(true)
        end

        it "should not compute hash" do
          Manifesto.should_receive(:compute_file_contents_hash).never
          Manifesto.cache
        end

        it "should not normalize the path" do
          Manifesto.should_receive(:normalize_path).never
          Manifesto.cache
        end
      end

      context "and path is for a valid file" do
        before(:each) do
          Manifesto.stub!(:get_file_paths).and_return(['/public/file1'])
          File.stub!(:file?).and_return(true)
          Manifesto.stub!(:compute_file_contents_hash).and_return('asdfsafasdfsdfszxsd')
        end

        it "should compute the hash" do
          Manifesto.should_receive(:compute_file_contents_hash).and_return('anything')
          Manifesto.cache
        end

        it "should normalize path" do
          Manifesto.should_receive(:normalize_path).with('./public', '/public/file1')
          Manifesto.cache
        end

        context "and return an array of values" do
          it "should return an array of 4 elements" do
             Manifesto.cache.size.should eql(4)
          end

          it "should have 'CACHE MANIFEST text in the first element of the return array'" do
            Manifesto.cache.first.should eql("CACHE MANIFEST\n")
          end

          it "should have 'generated by manifesto text'" do
            Manifesto.cache.should be_include("# Generated by manifesto (http://github.com/johntopley/manifesto)\n")
          end

          it "should have the file name in the last element of the array" do
            Manifesto.cache.last.should eql("/file1\n")
          end

          it "should return the hash" do
            Manifesto.cache.should be_include("# Hash: f2d6ac219e22a0eed707a24d65777a0e\n")
          end
        end
      end
    end
  end
end