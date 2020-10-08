{ lib
, pythonOlder
, buildPythonPackage
, fetchFromGitHub
  # Python requirements
, cython
, dill
, fastjsonschema
, jsonschema
, numpy
, networkx
, ply
, psutil
, python-constraint
, python-dateutil
, retworkx
, scipy
, sympy
, withVisualization ? false
  # Python visualization requirements, optional
, ipywidgets
, matplotlib
, pillow
, pydot
, pygments
, pylatexenc
, seaborn
  # Crosstalk-adaptive layout pass
, withCrosstalkPass ? false
, z3
  # Classical function -> Quantum Circuit compiler
, withClassicalFunctionCompiler ? false
, tweedledum ? null
  # test requirements
, ddt
, hypothesis
, nbformat
, nbconvert
, pytestCheckHook
, python
}:

let
  visualizationPackages = [
    ipywidgets
    matplotlib
    pillow
    pydot
    pygments
    pylatexenc
    seaborn
  ];
  crosstalkPackages = [ z3 ];
  classicalCompilerPackages = [ tweedledum ];
in

buildPythonPackage rec {
  pname = "qiskit-terra";
  version = "0.16.1";

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "Qiskit";
    repo = pname;
    rev = version;
    sha256 = "0007glsbrvq9swamvz8r76z9nzh46b388y0ds1dypczxpwlp9xcq";
  };

  nativeBuildInputs = [ cython ];

  propagatedBuildInputs = [
    dill
    fastjsonschema
    jsonschema
    numpy
    networkx
    ply
    psutil
    python-constraint
    python-dateutil
    retworkx
    scipy
    sympy
  ] ++ lib.optionals withVisualization visualizationPackages
  ++ lib.optionals withCrosstalkPass crosstalkPackages
  ++ lib.optionals withClassicalFunctionCompiler classicalCompilerPackages;

  # *** Tests ***
  checkInputs = [
    pytestCheckHook
    ddt
    hypothesis
    nbformat
    nbconvert
  ] ++ lib.optionals (!withVisualization) visualizationPackages;

  pythonImportsCheck = [
    "qiskit"
    "qiskit.transpiler.passes.routing.cython.stochastic_swap.swap_trial"
  ];

  pytestFlagsArray = [
    "--ignore=test/randomized/test_transpiler_equivalence.py" # collection requires qiskit-aer, which would cause circular dependency
  ] ++ lib.optionals (!withClassicalFunctionCompiler ) [
    "--ignore=test/python/classical_function_compiler/"
  ];

  # Moves tests to $PACKAGEDIR/test. They can't be run from /build because of finding
  # cythonized modules and expecting to find some resource files in the test directory.
  preCheck = ''
    export PACKAGEDIR=$out/${python.sitePackages}
    echo "Moving Qiskit test files to package directory"
    cp -r $TMP/$sourceRoot/test $PACKAGEDIR
    cp -r $TMP/$sourceRoot/examples $PACKAGEDIR
    cp -r $TMP/$sourceRoot/qiskit/schemas/examples $PACKAGEDIR/qiskit/schemas/

    # run pytest from Nix's $out path
    pushd $PACKAGEDIR
  '';
  postCheck = ''
    rm -rf test
    rm -rf examples
    popd
  '';


  meta = with lib; {
    description = "Provides the foundations for Qiskit.";
    longDescription = ''
      Allows the user to write quantum circuits easily, and takes care of the constraints of real hardware.
    '';
    homepage = "https://qiskit.org/terra";
    downloadPage = "https://github.com/QISKit/qiskit-terra/releases";
    changelog = "https://qiskit.org/documentation/release_notes.html";
    license = licenses.asl20;
    maintainers = with maintainers; [ drewrisinger ];
  };
}
