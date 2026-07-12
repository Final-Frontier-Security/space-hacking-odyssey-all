#ifndef NOS3_BLACKBOARDHARDWAREMODEL_HPP
#define NOS3_BLACKBOARDHARDWAREMODEL_HPP

/*
** Includes
*/
#include <map>

#include <boost/tuple/tuple.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>

#include <Client/Bus.hpp>
#include <Uart/Client/Uart.hpp> /* TODO: Change if your protocol bus is different (e.g. SPI, I2C, etc.) */

#include <sim_i_data_provider.hpp>
#include <blackboard_data_point.hpp>
#include <sim_i_hardware_model.hpp>
#include <blackboard_data.hpp>


/*
** Defines
*/
#define BLACKBOARD_SIM_SUCCESS 0
#define BLACKBOARD_SIM_ERROR   1


/*
** Namespace
*/
namespace Nos3
{
    namespace bip = boost::interprocess;

    /* Standard for a hardware model */
    class BlackboardHardwareModel : public SimIHardwareModel
    {
    public:
        /* Constructor and destructor */
        BlackboardHardwareModel(const boost::property_tree::ptree& config);
        ~BlackboardHardwareModel(void);

        void send_periodic_data_to_shmem(NosEngine::Common::SimTime time);
    private:
        /* Private helper methods */
        void command_callback(NosEngine::Common::Message msg); /* Handle backdoor commands and time tick to the simulator */

        /* Private data members */
        std::unique_ptr<NosEngine::Client::Bus>             _time_bus; /* Standard */

        SimIDataProvider*                                   _blackboard_dp; /* Only needed if the sim has a data provider */

        /* Internal state data */
        std::string                                         _shm_name;
        bip::mapped_region                                  _shm_region;
        BlackboardData*                                     _blackboard_data;
        std::uint16_t                                       _ticks_between_shmem_saves;
        std::uint16_t                                       _ticks_to_wait_at_startup;
        std::uint8_t                                        _enabled;
    };

}

#endif
