from openc3.script import *

class Cfdp:
    """Helper library for CFDP file transfer operations."""

    def download_file(self, source, destination="download.bin"):
        """Download a file from the satellite's /cf/ directory."""
        cmd(f"CFDP DOWNLOAD_FROM_SATELLITE_CC with SOURCE '{source}', DESTINATION '{destination}'")

    def upload_file(self, source, destination="/cf/upload.bin"):
        """Upload a file to the satellite's /cf/ directory."""
        cmd(f"CFDP UPLOAD_TO_SATELLITE_CC with SOURCE '{source}', DESTINATION '{destination}'")
