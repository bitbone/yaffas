#!/bin/bash
set -e

USERNAME="$1"
PASSWORD="$2"

source ~/.update-zarafa-client 2>/dev/null

URL="http://download.zarafa.com/supported"
STATUS=${STATUS:-final}
VERSION="7.1"
RELEASE="7.1.3-40304"
CMD="wget --user=$USERNAME --password=$PASSWORD -qc"

[[ -z $USERNAME ]] && read -p "Username: " USERNAME
[[ -z $PASSWORD ]] && read -p "Password: " PASSWORD

extract_versions() {
	sed -rne 's:.*>((([0-9\.d\-]+)|beta)+)/<.*:\1:p' | sort -V
}

extract_client_binary() {
	sed -rne \
		's:.*["/](zarafaclient-'$VERSION'([0-9\.-]+|beta)+.msi)">.*:\1:p'
}

extract_client_en_binary() {
	sed -rne \
		's:.*["/](zarafaclient-en-'$VERSION'([0-9\.-]+|beta)+.msi)">.*:\1:p'
}

AVAILABLE_VERSIONS=$($CMD "$URL/$STATUS/" -qO - | extract_versions)
LATEST_MAJOR_VERSION=$(echo "$AVAILABLE_VERSIONS" | tail -n1)
if [[ $LATEST_MAJOR_VERSION != $VERSION ]]; then
	echo "WARNING: Latest major version is $LATEST_MAJOR_VERSION, but"
	echo "         I am configured to use $VERSION."
	echo "Press ENTER to continue"
	read
fi

AVAILABLE_RELEASES=$($CMD "$URL/$STATUS/$VERSION" -qO - | extract_versions)
LATEST_RELEASE=$(echo "$AVAILABLE_RELEASES" | tail -n1)
if [[ $LATEST_RELEASE != $RELEASE ]]; then
	echo "Available $VERSION releases:"
	echo $AVAILABLE_RELEASES
	echo
	echo "Configured release: $RELEASE"
	echo "Latest release: $LATEST_RELEASE"
	echo
	echo "What release should I use?"
	read -p "Release [latest]: " RELEASE
	[[ -z $RELEASE ]] && RELEASE=$LATEST_RELEASE
fi
echo -n "Using release $RELEASE "

if [[ $RELEASE == $LATEST_RELEASE ]]; then
	echo "(latest)"
else
	echo "(non-latest)"
fi

PKGDIR="$(dirname "$0")/../base/yaffas-software"
BASEURL="$URL/$STATUS/$VERSION/$RELEASE"
CLIENT_EN_BINARY=$($CMD "$BASEURL/windows/" -qO - | extract_client_en_binary)
CLIENT_BINARY=$($CMD "$BASEURL/windows/" -qO - | extract_client_binary)
mkdir -p "${PKGDIR}/software/zarafa"
pushd "${PKGDIR}/software/zarafa" >/dev/null
git rm -qf zarafa*.{exe,msi} 2>/dev/null || true
echo "Downloading zarafamigrationtool.exe..."
$CMD "$BASEURL/windows/zarafamigrationtool.exe"
echo "Downloading $CLIENT_EN_BINARY..."
$CMD "$BASEURL/windows/$CLIENT_EN_BINARY"
echo "Downloading $CLIENT_BINARY..."
$CMD "$BASEURL/windows/$CLIENT_BINARY"
cd ../..
echo "Updating version in redhat/yaffas-software.spec..."
sed -re \
		's:zarafaclient-[0-9\.\-]{8,}\.msi:'$CLIENT_BINARY':g' \
		-i redhat/*.spec
echo "Updating version in debian/postinst..."
sed -re \
		's:zarafaclient-[0-9\.\-]{8,}\.msi:'$CLIENT_BINARY':g' \
		-i debian/postinst
echo "Done"
