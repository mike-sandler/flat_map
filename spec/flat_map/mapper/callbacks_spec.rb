require 'spec_helper'

module FlatMap
  module CallbacksSpec
    class MountMapper < Mapper
      map :attr_c

      set_callback :validate, :before, :set_c

      def set_c
        self.attr_c = 'mounted before validate'
      end
    end

    class SpecMapper < Mapper
      map :attr_a

      set_callback :save, :before, :set_a

      trait :with_b do
        map :attr_b

        set_callback :validate, :before, :set_b

        def set_b
          self.attr_b = 'before validate'
        end
      end

      def set_a
        self.attr_a = 'before save'
      end

      mount :mount,
        :mapper_class_name => 'FlatMap::CallbacksSpec::MountMapper',
        :target            => lambda{ |_| OpenStruct.new }
    end
  end

  describe 'Callbacks' do
    let(:mapper) do
      CallbacksSpec::SpecMapper.new(OpenStruct.new, :with_b) do
        set_callback :validate, :before, :extension_set_b

        def extension_set_b
          self.attr_b = 'extension value'
        end
      end
    end

    it 'should call callbacks once' do
      mapper.should_receive(:set_a).once
      mapper.save
    end

    specify 'validation callbacks' do
      mapper.valid?
      mapper.attr_a.should be_nil
      mapper.attr_b.should == 'before validate'
      mapper.attr_c.should == 'mounted before validate'
    end

    specify 'save callbacks' do
      mapper.save
      mapper.attr_a.should == 'before save'
    end

    context 'extension trait and named traits' do
      it 'should process extension first' do
        mapper.extension.should_receive(:extension_set_b).once.and_call_original
        mapper.valid?
        mapper.attr_b.should == 'before validate'
      end
    end
  end
end
