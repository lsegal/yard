before_run :run_verifier

protected

def run_verifier
  return verifier.call(self) if options.verifier
end