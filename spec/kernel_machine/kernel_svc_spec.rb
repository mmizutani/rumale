require 'spec_helper'

RSpec.describe SVMKit::KernelMachine::KernelSVC do
  let(:samples) { SVMKit::Utils.restore_nmatrix(Marshal.load(File.read(__dir__ + '/../test_samples_xor.dat'))) }
  let(:labels) { SVMKit::Utils.restore_nmatrix(Marshal.load(File.read(__dir__ + '/../test_labels_xor.dat'))) }
  let(:kernel_matrix) { SVMKit::PairwiseMetric::rbf_kernel(samples, nil, 1.0) }
  let(:estimator) { described_class.new(penalty: 1.0, max_iter: 1000, random_seed: 1) }

  it 'classifies xor data.' do
    n_samples, = samples.shape[0]
    estimator.fit(kernel_matrix, labels)
    expect(estimator.weight_vec.size).to eq(n_samples)
    score = estimator.score(kernel_matrix, labels)
    expect(score).to eq(1.0)
  end

  it 'dumps and restores itself using Marshal module.' do
    estimator.fit(kernel_matrix, labels)
    copied = Marshal.load(Marshal.dump(estimator))
    expect(estimator.class).to eq(copied.class)
    expect(estimator.params[:reg_param]).to eq(copied.params[:reg_param])
    expect(estimator.params[:max_iter]).to eq(copied.params[:max_iter])
    expect(estimator.params[:random_seed]).to eq(copied.params[:random_seed])
    expect(estimator.weight_vec).to eq(copied.weight_vec)
    expect(estimator.rng).to eq(copied.rng)
  end
end
