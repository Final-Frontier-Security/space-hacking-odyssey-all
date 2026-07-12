#include <generic_imu_shmem_data_provider.hpp>

namespace Nos3
{
    REGISTER_DATA_PROVIDER(Generic_imuShmemDataProvider,"GENERIC_IMU_SHMEM_PROVIDER");

    extern ItcLogger::Logger *sim_logger;

    Generic_imuShmemDataProvider::Generic_imuShmemDataProvider(const boost::property_tree::ptree& config) : SimIDataProvider(config)
    {
        sim_logger->trace("Generic_imuShmemDataProvider::Generic_imuShmemDataProvider:  Constructor executed");
        const std::string shm_name = config.get("simulator.hardware-model.data-provider.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't let this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());    
    }

    boost::shared_ptr<SimIDataPoint> Generic_imuShmemDataProvider::get_data_point(void) const
    {
        boost::shared_ptr<Generic_imuDataPoint> dp;
        {
            dp = boost::shared_ptr<Generic_imuDataPoint>(
                new Generic_imuDataPoint(_blackboard_data->GyroRate[0], _blackboard_data->GyroRate[1], _blackboard_data->GyroRate[2], 
                    _blackboard_data->AccelAcc[0], _blackboard_data->AccelAcc[1], _blackboard_data->AccelAcc[2]));
        }
        sim_logger->debug("Generic_imuShmemDataProvider::get_data_point: gyro rate=%f, %f, %f, acceleration=%f, %f, %f", 
            dp->get_generic_imu_gyro_x(), dp->get_generic_imu_gyro_y(), dp->get_generic_imu_gyro_z(), 
            dp->get_generic_imu_acc_x(), dp->get_generic_imu_acc_y(), dp->get_generic_imu_acc_z());
        return dp;
    }
}
