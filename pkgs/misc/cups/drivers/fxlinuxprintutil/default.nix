{ stdenv, lib, fetchzip, dpkg, autoPatchelfHook, cups, tcl, tk, xorg, ed, makeWrapper }:
let
  debPlatform =
    if stdenv.hostPlatform.system == "x86_64-linux" then "amd64"
    else if stdenv.hostPlatform.system == "i686-linux" then "i386"
         else throw "Unsupported system: ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation rec {
  name = "fxlinuxprintutil-${version}";
  version = "1.1.1-1";

  src = fetchzip {
    url = "https://onlinesupport.fujixerox.com/driver_downloads/fxlinuxpdf112119031.zip";
    sha256 = "1mv07ch6ysk9bknfmjqsgxb803sj6vfin29s9knaqv17jvgyh0n3";
    curlOpts = "--user-agent Mozilla/5.0";  # HTTP 410 otherwise
  };

  patches = [ ./fxlputil.patch ./fxlputil.tcl.patch ./fxlocalechk.tcl.patch ];

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [ cups tcl tk ];

  sourceRoot = ".";
  unpackCmd = "dpkg-deb -x $curSrc/fxlinuxprintutil_${version}_${debPlatform}.deb .";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    mv usr/* $out

    substituteInPlace $out/bin/fxlocalechk.tcl --subst-var-by libX11 "${xorg.libX11}"

    wrapProgram $out/bin/fxlputil --prefix PATH : ${lib.makeBinPath [ tcl tk ]}
  '';

  meta = with stdenv.lib; {
    description = "Fuji Xerox Linux Printer Driver";
    longDescription = ''
      DocuPrint P365/368 d
      DocuPrint CM315/318 z
      DocuPrint CP315/318 dw
      ApeosPort-VI C2271/C3370/C3371/C4471/C5571/C6671/C7771
      DocuCentre-VI C2271/C3370/C3371/C4471/C5571/C6671/C7771
      DocuPrint 3205 d/3208 d/3505 d/3508 d/4405 d/4408 d
    '';
    homepage = https://onlinesupport.fujixerox.com;
    license = licenses.unfree;
    maintainers = with maintainers; [ delan ];
    platforms = platforms.linux;
  };
}
