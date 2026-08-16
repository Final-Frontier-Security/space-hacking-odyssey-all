# Software Bill of Materials (SBOM)

## Host Operating Systems

| Component | OS | Version | Notes |
|-----------|-----|---------|-------|
| Satellite | Ubuntu | 24.04 LTS | AWS EC2, c5.2xlarge |
| Ground Station | Ubuntu | 24.04 LTS | AWS EC2, c5.4xlarge |
| Operator Station | Ubuntu | 24.04 LTS | AWS EC2, c5.2xlarge + NICE DCV |

## Container Runtime

| Software | Version | Purpose |
|----------|---------|---------|
| Docker Engine | 27.x | Container orchestration |
| Docker Compose | v2.x | Multi-container management |

## Satellite Components

| Software | Version/Source | License | Purpose |
|----------|---------------|---------|---------|
| NASA cFE (core Flight Executive) | Bootes | Apache 2.0 | Flight software framework |
| NASA OSAL | Bootes | Apache 2.0 | OS abstraction layer |
| NOS3 (NASA Operational Simulator) | nos3-main | NASA Open Source | Hardware-in-the-loop sim framework |
| NOS Engine | NOS3 bundled | NASA | Inter-process simulation bus |
| 42 Simulator | nos3-main branch | NASA Open Source | Orbital mechanics & attitude sim |
| CryptoLib | NOS3 bundled | Apache 2.0 | Encryption for radio link |
| ivvitc/nos3-64 Docker image | 20251107 | - | Build/runtime container for cFS |

### cFS Applications (Flight Software)

| App | Purpose |
|-----|---------|
| CI / CI_LAB | Command Ingest |
| TO / TO_LAB | Telemetry Output |
| SCH | Scheduler |
| CF | CCSDS File Delivery Protocol |
| DS | Data Storage |
| FM | File Manager |
| LC | Limit Checker |
| SC | Stored Commands |
| SBN | Software Bus Network |
| Generic ADCS | Attitude Determination & Control |
| Generic CSS/FSS/IMU/MAG | Sensor interfaces |
| Generic Star Tracker | Star tracker interface |
| Generic Reaction Wheel | Actuator interface |
| Generic Torquer | Magnetic torquer interface |
| Generic Thruster | Thruster interface |
| Generic EPS | Electrical Power System |
| Generic Radio | Radio interface |
| Novatel OEM615 | GPS receiver |
| ArduCAM | Camera payload |
| Sample | Example app |
| CFDP | Custom file transfer (NOS3 specific) |
| IPS | Intrusion Prevention System (custom) |
| IDS | Intrusion Detection System (custom) |

### Hardware Simulators

| Simulator | Connects To |
|-----------|-------------|
| generic_css_sim | 42 (sun sensor data) |
| generic_fss_sim | 42 (fine sun sensor) |
| generic_imu_sim | 42 (inertial measurement) |
| generic_mag_sim | 42 (magnetometer) |
| generic_star_tracker_sim | 42 (star tracker quaternion) |
| generic_reaction_wheel_sim | 42 (wheel momentum) |
| generic_torquer_sim | 42 (magnetic torquer) |
| generic_thruster_sim | 42 (thruster) |
| generic_eps_sim | NOS Engine |
| generic_radio_sim | NOS Engine |
| novatel_oem615_sim | 42 (GPS) |
| arducam_sim | NOS Engine |
| sample_sim | NOS Engine |

## Ground Station Components

| Software | Version | License | Purpose |
|----------|---------|---------|---------|
| OpenC3 COSMOS | 6.0.1 | AGPL 3.0 | Ground control system |
| Redis | 7.x | BSD | State store / message broker |
| MinIO | 2024-12 | AGPL 3.0 | Object storage (S3-compatible) |
| Traefik | 2.x | MIT | Reverse proxy / TLS termination |
| Ruby | 3.2.6 | BSD | OpenC3 runtime |
| Python | 3.x | PSF | CFDP microservice runtime |
| vsftpd | 3.x | GPL 2.0 | FTP server for file staging |

## Operator Station Components

| Software | Version | License | Purpose |
|----------|---------|---------|---------|
| NICE DCV | Latest | AWS proprietary | Remote desktop |
| GNOME Desktop | 42/43 | GPL | Desktop environment |
| Firefox | Latest | MPL 2.0 | Web browser (OpenC3 access) |
| Docker | 27.x | Apache 2.0 | 42 viewer container runtime |

## AWS Infrastructure

| Service | Purpose |
|---------|---------|
| EC2 | Compute instances |
| VPC | Network isolation |
| Route53 | Private DNS (groundstation.earth, spacevehicle.space) |
| EBS | Block storage (gp3) |
| CloudFormation | Infrastructure as code |

## Network Protocols

| Protocol | Port(s) | Purpose |
|----------|---------|---------|
| UDP | 5012 | Commands (ground → satellite) |
| UDP | 5013-5053 | Telemetry (satellite → ground, per-sat ports) |
| UDP | 6010-6011 | CryptoLib encrypted link |
| TCP | 10001 | 42 graphics IPC (satellite → opstation) |
| TCP | 443 | OpenC3 web UI (HTTPS) |
| TCP | 22 | SSH |
| TCP/UDP | 8443 | NICE DCV remote desktop |
| TCP | 21 | FTP (file staging) |
| UDP | 5012 | Holodeck command injection |

## Custom Components (This Project)

| Component | Language | Purpose |
|-----------|----------|---------|
| 42 IPC Patch | C | Multi-threaded socket handling for 42 |
| CFDP App + Microservice | C / Python | Chunked file upload/download |
| IPS App | C | Software bus app allowlist enforcement |
| IDS App | C | Canary file integrity monitoring |
| Comms Windows Script | Python | Simulated LEO pass scheduling |
| Multi-satellite Build Script | Bash | OpenC3 multi-target plugin generator |
