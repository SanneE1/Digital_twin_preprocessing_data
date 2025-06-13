import numpy as np
import pandas as pd
import subprocess
import os
import uuid
import platform
from scipy import stats
import matplotlib.pyplot as plt
import corner
import emcee
from multiprocessing import Pool, cpu_count

# Function to define priors for your specific parameters
def log_prior(theta):
    # Unpack parameters
    lambda_param, dens_opt, sigma, kC_high, kC_low = theta
    
    # Priors for real-valued parameters (lambda and sigma)
    # Assuming lambda should be positive and typically less than 1
    if lambda_param <= 0:
        return -np.inf
    lambda_prior = stats.gamma.logpdf(lambda_param, a=2, scale=0.2)  # peaks around 0.4
    
    # Prior for sigma (positive real number)
    if sigma <= 0:
        return -np.inf
    sigma_prior = stats.gamma.logpdf(sigma, a=2, scale=0.2)
    
    # Priors for integer parameters
    # Using discrete normal distributions, centered at reasonable values
    dens_prior = stats.norm.logpdf(kC_low, loc=3, scale=1)
    kC_high_prior = stats.norm.logpdf(kC_high, loc=14, scale=2)
    kC_low_prior = stats.norm.logpdf(dens_opt, loc=10, scale=2)
    
    # Return sum of log priors
    return lambda_prior + sigma_prior + dens_prior + kC_high_prior + kC_low_prior

# Function to get the executable name based on the platform
def get_executable_name():
    system = platform.system()
    if system == "Windows":
        return "model_rabbit_param_selection.exe"
    else:  # Linux, macOS, etc.
        return "./model_rabbit_param_selection"

# Function to run the executable and get results with unique output file
def run_executable(theta):
    lambda_param, dens_opt, sigma, kC_high, kC_low = theta
    
    # Round integer parameters
    dens_opt_rounded = round(dens_opt)
    kC_high_rounded = round(kC_high)
    kC_low_rounded = round(kC_low)
    
    # Create a unique output directory for this walker
    unique_id = str(uuid.uuid4())[:8]
    output_dir = os.path.join("output_data", unique_id)
    output_file = os.path.join(output_dir, "result_for_mcmc.csv")
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Get the correct executable name for the current platform
    executable = get_executable_name()
    
    # Command to run the executable with parameters
    cmd = [
        executable,
        os.path.join("data", "pre_processed_data", "parameter_values_500_donana.txt"),
        output_file,  # Pass the unique output file path to the executable
        str(lambda_param),
        str(dens_opt_rounded),
        str(sigma),
        str(kC_high_rounded),
        str(kC_low_rounded)
    ]
    
    try:
        # Make the executable file executable on non-Windows platforms
        if platform.system() != "Windows":
            os.chmod(executable, 0o755)
        
        # Open debug output file in a cross-platform way
        with open('debug_output.txt', 'w') as debug_file:
            result = subprocess.run(cmd, check=True, stdout=debug_file, stderr=subprocess.PIPE)
        
        # Read the output CSV
        model_data = pd.read_csv(output_file)
        observed_data = pd.read_csv(os.path.join("data", "pre_processed_data", "rabbit_observed_for_mcmc.csv"))
        
        # Merge the datasets on year, x, y to get matching rows
        merged_data = pd.merge(
            model_data, 
            observed_data,
            on=['sim_year', 'col', 'row'],
            suffixes=('_model', '_observed')
        )
        
        if len(merged_data) == 0:
            print(f"No matching data points found for parameters: {theta}")
            return None
            
        # Clean up - remove the temporary output directory
        try:
            if os.path.exists(output_dir):
                for file in os.listdir(output_dir):
                    os.remove(os.path.join(output_dir, file))
                os.rmdir(output_dir)
        except Exception as e:
            print(f"Warning: Could not clean up directory {output_dir}: {e}")
            
        return merged_data
        
    except subprocess.CalledProcessError as e:
        print(f"Error running executable: {e}")
        return None
    except Exception as e:
        print(f"Error processing results: {e}")
        return None

# Function to calculate likelihood by comparing with observed data
def log_likelihood(theta):
    # Run the executable with current parameters
    merged_data = run_executable(theta)
    
    if merged_data is None:
        return -np.inf
    
    # Calculate the difference between model and observed values
    residuals = merged_data['result'] - merged_data['observed']
    
    # Calculate log likelihood assuming Gaussian errors
    error_term = np.std(merged_data['observed']) * 0.1  # 10% of observed std
    n = len(residuals)
    log_like = -0.5 * np.sum(residuals**2) / (error_term**2) - n * np.log(error_term) - 0.5 * n * np.log(2 * np.pi)
    
    return log_like

# The full posterior probability
def log_probability(theta):
    lp = log_prior(theta)
    if not np.isfinite(lp):
        return -np.inf
    return lp + log_likelihood(theta)

# The main worker function, defined at the module level
def run_mcmc_worker(args):
    return log_probability(args)

# Main function to run MCMC
def run_mcmc(nwalkers=32, nsteps=1000, ndim=5, threads=None):
    # If threads is None, use one less than the number of cores (leave one for system)
    if threads is None:
        threads = max(1, cpu_count() - 1)

    # Initial positions for walkers
    initial_lambda = np.random.gamma(2, 0.2, nwalkers)
    initial_dens = np.random.normal(3, 1, nwalkers)
    initial_sigma = np.random.gamma(2, 0.2, nwalkers)
    initial_kC_high = np.random.normal(14, 2, nwalkers)
    initial_kC_low = np.random.normal(10, 2, nwalkers)
    
    # Combine into initial positions
    initial_pos = np.column_stack([
        initial_lambda, initial_dens, initial_sigma, 
        initial_kC_high, initial_kC_low
    ])
    
    # Set up and run sampler
    # Change how we integrate with multiprocessing
    if threads > 1:
        print(f"Starting MCMC sampling with {threads} parallel processes...")
        with Pool(threads) as pool:
            sampler = emcee.EnsembleSampler(
                nwalkers, 
                ndim, 
                log_probability,  # Direct function reference
                pool=pool
            )
            sampler.run_mcmc(initial_pos, nsteps, progress=True)
    else:
        # Run without multiprocessing if only 1 thread is requested
        print("Starting MCMC sampling in single-process mode...")
        sampler = emcee.EnsembleSampler(nwalkers, ndim, log_probability)
        sampler.run_mcmc(initial_pos, nsteps, progress=True)
    
    print("MCMC sampling complete")
    return sampler

# Analyze and plot results
def analyze_results(sampler, burnin=200):
    samples = sampler.get_chain(discard=burnin, flat=True)
    
    # Parameter names for your specific case
    param_names = ["lambda", "dens_opt", "sigma", "kC_high", "kC_low"]
    
    # Save posterior samples to CSV
    samples_df = pd.DataFrame(samples, columns=param_names)
    samples_df.to_csv("posterior_samples.csv", index=False)
    print("Posterior distribution saved to posterior_samples.csv")
    
    # Print parameter estimates
    for i, name in enumerate(param_names):
        mcmc_sample = samples[:, i]
        median = np.median(mcmc_sample)
        credible_interval = np.percentile(mcmc_sample, [2.5, 97.5])
        print(f"\n{name}:")
        print(f"Median: {median:.3f}")
        print(f"95% Credible Interval: ({credible_interval[0]:.3f}, {credible_interval[1]:.3f})")
        
        # For integer parameters, also show rounded values
        if name in ['dens_opt', 'kC_high', 'kC_low']:
            rounded_median = round(median)
            print(f"Rounded median: {rounded_median}")
    
    # Create and save corner plot
    fig = corner.corner(samples, labels=param_names,
                       quantiles=[0.16, 0.5, 0.84],
                       show_titles=True)
    plt.savefig("parameter_posterior.png")
    plt.close()
    
    # Create trace plots
    fig, axes = plt.subplots(5, figsize=(10, 12), sharex=True)
    samples = sampler.get_chain()
    for i in range(5):
        ax = axes[i]
        ax.plot(samples[:, :, i], "k", alpha=0.3)
        ax.set_ylabel(param_names[i])
    axes[-1].set_xlabel("Step Number")
    plt.savefig("parameter_traces.png")
    plt.close()
    
    # Save additional summary statistics
    summary_stats = {}
    for i, name in enumerate(param_names):
        mcmc_sample = samples[:, i]
        summary_stats[f"{name}_mean"] = np.mean(mcmc_sample)
        summary_stats[f"{name}_median"] = np.median(mcmc_sample)
        summary_stats[f"{name}_std"] = np.std(mcmc_sample)
        for p in [2.5, 16, 84, 97.5]:
            summary_stats[f"{name}_p{p}"] = np.percentile(mcmc_sample, p)
    
    # Save summary statistics to CSV
    pd.DataFrame([summary_stats]).to_csv("posterior_summary.csv", index=False)
    print("Summary statistics saved to posterior_summary.csv")

if __name__ == "__main__":
    # Number of CPU cores to use
    # num_threads = os.cpu_count() - 1  # Leave one core free for system operations
    
    # Run the MCMC with parallel processing
    sampler = run_mcmc(nwalkers=12, nsteps=10000, threads=12)
    
    # Analyze and plot the results
    analyze_results(sampler, burnin=200)
    
    print("\nAnalysis complete. Check parameter_posterior.png and parameter_traces.png for visualizations.")