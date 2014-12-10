require 'package'

RSpec.describe Package do
  context 'instance' do
    let(:package) { Package.new('spec/fixtures/empty_package') }

    it { expect(package).to be_a Module }
  end
end

RSpec.describe 'Kernel#import' do
  before(:each) { Package.reload! }

  [Module, Object].each do |ctx|
    let(:package_name) { 'spec/fixtures/empty_package' }
    let(:target) { nil }
    let(:pak) do
      t = target
      n = package_name
      context.instance_eval { import(n, to: t) }
    end

    context "called inside #{ctx.name}.new" do
      let(:context) { ctx.new }

      it 'should import a package as a value' do
        expect(pak).to be_a Package
        expect(context).not_to respond_to :empty_package
        expect do
          context.instance_eval { EmptyPackage }
        end.to raise_error NameError
        expect do
          context.instance_eval { empty_package }
        end.to raise_error NameError
      end

      it 'should import a package as a method' do
        pak = nil
        context = Module.new do
          pak = import('spec/fixtures/empty_package', to: :method)
        end

        expect(context).to respond_to :empty_package
        expect(context.empty_package).to eq pak
      end

      it 'should import a package as a const' do
        pak = nil
        context = Module.new do
          pak = import('spec/fixtures/empty_package', to: :const)
        end

        expect(context).to have_constant :EmptyPackage
        expect(context::EmptyPackage).to eq pak
      end

      it 'should import a package as a local' do
        pending 'not ready yet'

        context = Module.new do
          import('spec/fixtures/empty_package', to: :local)
        end

        expect(context.instance_eval { empty_package }).to be_a Package
      end
    end
  end
end
