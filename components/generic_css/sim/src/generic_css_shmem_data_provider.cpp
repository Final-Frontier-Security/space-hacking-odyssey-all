#include <generic_css_shmem_data_provider.hpp>

namespace Nos3
{
    REGISTER_DATA_PROVIDER(Generic_cssShmemDataProvider,"GENERIC_CSS_SHMEM_PROVIDER");

    extern ItcLogger::Logger *sim_logger;

    Generic_cssShmemDataProvider::Generic_cssShmemDataProvider(const boost::property_tree::ptree& config) : SimIDataProvider(config)
    {
        sim_logger->trace("Generic_cssShmemDataProvider::Generic_cssShmemDataProvider:  Constructor executed");
        const std::string shm_name = config.get("simulator.hardware-model.data-provider.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't le this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());
        _scale_factor = config.get("simulator.hardware-model.data-provider.42-css-scale-factor", 1.0);
    }

    boost::shared_ptr<SimIDataPoint> Generic_cssShmemDataProvider::get_data_point(void) const
    {
        sim_logger->trace("Generic_cssShmemDataProvider::get_data_point:  Executed");

        /* Get the 42 data */
        boost::shared_ptr<Generic_cssDataPoint> dp;
        {
            dp = boost::shared_ptr<Generic_cssDataPoint>(
                new Generic_cssDataPoint(_scale_factor,
                    _blackboard_data->CSSValid[0], _blackboard_data->CSSValid[1], _blackboard_data->CSSValid[2], 
                    _blackboard_data->CSSValid[3], _blackboard_data->CSSValid[4], _blackboard_data->CSSValid[5], 
                    _blackboard_data->CSSIllum[0], _blackboard_data->CSSIllum[1], _blackboard_data->CSSIllum[2], 
                    _blackboard_data->CSSIllum[3], _blackboard_data->CSSIllum[4], _blackboard_data->CSSIllum[5]));
        }
        return dp;
    }
}
